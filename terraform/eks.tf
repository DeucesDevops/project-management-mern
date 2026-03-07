###############################################################################
# EKS Cluster
###############################################################################

locals {
  cluster_name = "${var.project_name}-${var.environment}"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  # ── Networking ───────────────────────────────────────────────────────────────
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # ── API Server Access ────────────────────────────────────────────────────────
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_endpoint_private_access      = true

  # ── Add-ons ──────────────────────────────────────────────────────────────────
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true # Must be installed before nodes join
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  # ── Managed Node Groups ──────────────────────────────────────────────────────
  eks_managed_node_groups = {
    # General-purpose on-demand nodes (system / critical workloads)
    system = {
      name           = "${local.cluster_name}-system"
      instance_types = var.node_group_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      disk_size = var.node_disk_size

      labels = {
        role = "system"
      }

      taints = []

      update_config = {
        max_unavailable_percentage = 33
      }
    }

    # Application workloads — mix of on-demand + spot for cost savings
    app = {
      name           = "${local.cluster_name}-app"
      instance_types = var.node_group_instance_types
      capacity_type  = "SPOT"

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      disk_size = var.node_disk_size

      labels = {
        role = "app"
      }

      taints = []

      update_config = {
        max_unavailable_percentage = 50
      }
    }
  }

  # ── Cluster Access (aws-auth ConfigMap) ──────────────────────────────────────
  # Add the current caller as a cluster admin so the Terraform executor can manage
  # Kubernetes resources via the kubernetes/helm providers.
  enable_cluster_creator_admin_permissions = true

  # ── Logging ──────────────────────────────────────────────────────────────────
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }
}

# ── IRSA for EBS CSI Driver ──────────────────────────────────────────────────
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.37"

  role_name             = "${local.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# ── IRSA for AWS Load Balancer Controller ─────────────────────────────────────
module "alb_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.37"

  role_name                              = "${local.cluster_name}-alb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# ── IRSA for Cluster Autoscaler ───────────────────────────────────────────────
module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.37"

  role_name                        = "${local.cluster_name}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

###############################################################################
# Helm Releases — AWS Load Balancer Controller + Cluster Autoscaler
###############################################################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.alb_controller_irsa_role.iam_role_arn
  }

  set {
    name  = "replicaCount"
    value = "2"
  }

  depends_on = [module.eks]
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.35.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa_role.iam_role_arn
  }

  depends_on = [module.eks]
}

# ── StorageClass: gp3 (default) ───────────────────────────────────────────────
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [module.eks]
}
