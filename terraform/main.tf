###############################################################################
# Root — Orchestrates all infrastructure modules
###############################################################################

locals {
  cluster_name = "${var.project_name}-${var.environment}"
}

# ── VPC ───────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  environment              = var.environment
  cluster_name             = local.cluster_name
  vpc_cidr                 = var.vpc_cidr
  availability_zones_count = var.availability_zones_count
}

# ── EKS ───────────────────────────────────────────────────────────────────────
module "eks" {
  source = "./modules/eks"

  cluster_name                         = local.cluster_name
  cluster_version                      = var.cluster_version
  vpc_id                               = module.vpc.vpc_id
  private_subnets                      = module.vpc.private_subnets
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  node_group_instance_types            = var.node_group_instance_types
  node_group_min_size                  = var.node_group_min_size
  node_group_max_size                  = var.node_group_max_size
  node_group_desired_size              = var.node_group_desired_size
  node_disk_size                       = var.node_disk_size
  aws_region                           = var.aws_region
}

# ── ECR ───────────────────────────────────────────────────────────────────────
module "ecr" {
  source = "./modules/ecr"

  project_name          = var.project_name
  image_retention_count = var.ecr_image_retention_count
}

# ── DocumentDB ────────────────────────────────────────────────────────────────
module "documentdb" {
  source = "./modules/documentdb"

  cluster_name           = local.cluster_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnets        = module.vpc.private_subnets
  node_security_group_id = module.eks.node_security_group_id
  enable_documentdb      = var.enable_documentdb
  instance_class         = var.docdb_instance_class
  instance_count         = var.docdb_instance_count
  master_username        = var.docdb_master_username
}

# ── ElastiCache ───────────────────────────────────────────────────────────────
module "elasticache" {
  source = "./modules/elasticache"

  cluster_name           = local.cluster_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnets        = module.vpc.private_subnets
  node_security_group_id = module.eks.node_security_group_id
  enable_elasticache     = var.enable_elasticache
  node_type              = var.elasticache_node_type
  num_cache_nodes        = var.elasticache_num_cache_nodes
}
