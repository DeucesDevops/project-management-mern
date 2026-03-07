###############################################################################
# VPC — Public + Private Subnets across multiple AZs
###############################################################################

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)

  # Divide the VPC CIDR into equal-sized subnets
  # First half → public, second half → private
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + var.availability_zones_count)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  # ── NAT Gateway ─────────────────────────────────────────────────────────────
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "production" # One NAT per AZ in prod
  one_nat_gateway_per_az = var.environment == "production"

  # ── DNS ─────────────────────────────────────────────────────────────────────
  enable_dns_hostnames = true
  enable_dns_support   = true

  # ── EKS-required subnet tags ─────────────────────────────────────────────────
  # Public subnets — used by the AWS Load Balancer Controller for internet-facing ALBs
  public_subnet_tags = {
    "kubernetes.io/role/elb"                              = 1
    "kubernetes.io/cluster/${local.cluster_name}"         = "shared"
  }

  # Private subnets — EKS nodes and internal load balancers
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                     = 1
    "kubernetes.io/cluster/${local.cluster_name}"         = "shared"
    "karpenter.sh/discovery"                              = local.cluster_name
  }
}
