###############################################################################
# Root Module — composes all child modules
###############################################################################

# ── Shared Data Sources & Locals ─────────────────────────────────────────────

data "aws_availability_zones" "available" { state = "available" }
data "aws_caller_identity" "current" {}

locals {
  cluster_name = "${var.project_name}-${var.environment}"

  azs             = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)
  public_subnets  = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  private_subnets = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, k + var.availability_zones_count)]

  # ── Connection strings assembled here so both k8s-apps and any CI scripts can use them
  mongo_host = var.enable_documentdb ? module.documentdb[0].endpoint : "mongodb"
  mongo_port = var.enable_documentdb ? tostring(module.documentdb[0].port) : "27017"
  mongo_tls  = var.enable_documentdb

  redis_host = var.enable_elasticache ? module.elasticache[0].primary_endpoint : "redis"
  redis_port = var.enable_elasticache ? tostring(module.elasticache[0].port) : "6379"
  redis_tls  = var.enable_elasticache

  # ── Passwords — use provided values or auto-generated randoms
  jwt_secret          = var.jwt_secret != null ? var.jwt_secret : random_password.jwt_secret.result
  mongo_root_password = var.mongo_root_password != null ? var.mongo_root_password : (
    var.enable_documentdb ? module.documentdb[0].master_password : random_password.mongo_password.result
  )
  redis_password = var.redis_password != null ? var.redis_password : (
    var.enable_elasticache ? module.elasticache[0].auth_token : random_password.redis_password.result
  )

  # ── ECR image defaults (used if caller does not override)
  server_image = var.server_image != "" ? var.server_image : "${module.ecr.server_repository_url}:latest"
  client_image = var.client_image != "" ? var.client_image : "${module.ecr.client_repository_url}:latest"
}

# ── Auto-generated Secrets (used when caller does not supply values) ──────────

resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

resource "random_password" "mongo_password" {
  length  = 32
  special = false
}

resource "random_password" "redis_password" {
  length  = 32
  special = false
}

###############################################################################
# Modules
###############################################################################

module "vpc" {
  source = "./modules/vpc"

  project_name    = var.project_name
  environment     = var.environment
  cluster_name    = local.cluster_name
  vpc_cidr        = var.vpc_cidr
  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
}

module "eks" {
  source = "./modules/eks"

  cluster_name             = local.cluster_name
  cluster_version          = var.cluster_version
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets
  aws_region               = var.aws_region

  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  node_group_instance_types = var.node_group_instance_types
  system_node_min           = 2
  system_node_max           = 4
  system_node_desired       = 2
  app_node_min              = var.node_group_min_size
  app_node_max              = var.node_group_max_size
  app_node_desired          = var.node_group_desired_size
  node_disk_size            = var.node_disk_size

  depends_on = [module.vpc]
}

module "ecr" {
  source = "./modules/ecr"

  project_name          = var.project_name
  image_retention_count = var.ecr_image_retention_count
}

# ── Optional: Amazon DocumentDB ───────────────────────────────────────────────
module "documentdb" {
  count  = var.enable_documentdb ? 1 : 0
  source = "./modules/documentdb"

  cluster_name           = local.cluster_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  node_security_group_id = module.eks.node_security_group_id
  master_username        = var.docdb_master_username
  instance_class         = var.docdb_instance_class
  instance_count         = var.docdb_instance_count

  depends_on = [module.eks]
}

# ── Optional: Amazon ElastiCache Redis ───────────────────────────────────────
module "elasticache" {
  count  = var.enable_elasticache ? 1 : 0
  source = "./modules/elasticache"

  cluster_name           = local.cluster_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  node_security_group_id = module.eks.node_security_group_id
  node_type              = var.elasticache_node_type
  num_nodes              = var.elasticache_num_cache_nodes

  depends_on = [module.eks]
}

# ── Kubernetes Application Resources ─────────────────────────────────────────
module "k8s_apps" {
  source = "./modules/k8s-apps"

  namespace = var.k8s_namespace
  app_name  = var.project_name

  server_image = local.server_image
  client_image = local.client_image

  server_replicas     = var.server_replicas
  server_min_replicas = var.server_min_replicas
  server_max_replicas = var.server_max_replicas
  client_replicas     = var.client_replicas
  client_min_replicas = var.client_min_replicas
  client_max_replicas = var.client_max_replicas

  jwt_secret          = local.jwt_secret
  mongo_root_user     = var.mongo_root_user
  mongo_root_password = local.mongo_root_password
  redis_password      = local.redis_password

  mongo_db   = var.mongo_db
  mongo_host = local.mongo_host
  mongo_port = local.mongo_port
  mongo_tls  = local.mongo_tls

  redis_host = local.redis_host
  redis_port = local.redis_port
  redis_tls  = local.redis_tls

  app_domain          = var.app_domain
  acm_certificate_arn = var.acm_certificate_arn
  alb_logs_bucket     = var.alb_logs_bucket

  depends_on = [module.eks]
}
