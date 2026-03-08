###############################################################################
# EKS Cluster
###############################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  cluster_endpoint_public_access       = var.endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  cluster_endpoint_private_access      = true

  # ── Cluster Add-ons ───────────────────────────────────────────────────────
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }

    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  # ── Managed Node Groups ───────────────────────────────────────────────────
  eks_managed_node_groups = {
    # Critical / system workloads — on-demand
    system = {
      name           = "${var.cluster_name}-system"
      instance_types = var.node_group_instance_types
      capacity_type  = "ON_DEMAND"
      min_size       = var.system_node_min
      max_size       = var.system_node_max
      desired_size   = var.system_node_desired
      disk_size      = var.node_disk_size
      labels         = { role = "system" }
      update_config  = { max_unavailable_percentage = 33 }
    }

    # Application workloads — spot for cost savings
    app = {
      name           = "${var.cluster_name}-app"
      instance_types = var.node_group_instance_types
      capacity_type  = "SPOT"
      min_size       = var.app_node_min
      max_size       = var.app_node_max
      desired_size   = var.app_node_desired
      disk_size      = var.node_disk_size
      labels         = { role = "app" }
      update_config  = { max_unavailable_percentage = 50 }
    }
  }

  enable_cluster_creator_admin_permissions = true

  cluster_enabled_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

###############################################################################
# IRSA Roles
###############################################################################

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.37"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.37"

  role_name                              = "${var.cluster_name}-alb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.37"

  role_name                        = "${var.cluster_name}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

###############################################################################
# Helm: AWS Load Balancer Controller + Cluster Autoscaler
###############################################################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set { name = "clusterName";                                                value = module.eks.cluster_name }
  set { name = "serviceAccount.create";                                      value = "true" }
  set { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"; value = module.alb_controller_irsa.iam_role_arn }
  set { name = "replicaCount";                                               value = "2" }

  depends_on = [module.eks]
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.35.0"

  set { name = "autoDiscovery.clusterName";                                      value = module.eks.cluster_name }
  set { name = "awsRegion";                                                      value = var.aws_region }
  set { name = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"; value = module.cluster_autoscaler_irsa.iam_role_arn }

  depends_on = [module.eks]
}

###############################################################################
# Default gp3 StorageClass
###############################################################################

resource "kubernetes_storage_class_v1" "gp3" {
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
