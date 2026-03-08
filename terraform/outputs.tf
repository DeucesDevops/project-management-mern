###############################################################################
# Root Outputs — delegated from child modules
###############################################################################

# ── VPC ──────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

# ── EKS ──────────────────────────────────────────────────────────────────────

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "configure_kubectl" {
  description = "Run this command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "alb_controller_role_arn" {
  value = module.eks.alb_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  value = module.eks.cluster_autoscaler_role_arn
}

# ── ECR ──────────────────────────────────────────────────────────────────────

output "ecr_client_repository_url" {
  value = module.ecr.client_repository_url
}

output "ecr_server_repository_url" {
  value = module.ecr.server_repository_url
}

output "ecr_registry" {
  description = "ECR registry base URL"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# ── DocumentDB ────────────────────────────────────────────────────────────────

output "docdb_endpoint" {
  description = "DocumentDB endpoint (empty if not enabled)"
  value       = var.enable_documentdb ? module.documentdb[0].endpoint : ""
  sensitive   = true
}

output "docdb_password_secret_arn" {
  description = "Secrets Manager ARN for DocumentDB master password"
  value       = var.enable_documentdb ? module.documentdb[0].master_password_secret_arn : ""
}

# ── ElastiCache ───────────────────────────────────────────────────────────────

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint (empty if not enabled)"
  value       = var.enable_elasticache ? module.elasticache[0].primary_endpoint : ""
  sensitive   = true
}

output "redis_auth_secret_arn" {
  description = "Secrets Manager ARN for Redis auth token"
  value       = var.enable_elasticache ? module.elasticache[0].auth_token_secret_arn : ""
}

# ── Kubernetes Apps ───────────────────────────────────────────────────────────

output "k8s_namespace" {
  value = module.k8s_apps.namespace
}

output "app_ingress_hostname" {
  description = "ALB hostname assigned to the ingress"
  value       = module.k8s_apps.ingress_hostname
}

# ── Auto-generated Secrets (printed once after apply) ─────────────────────────
# Store these in a secrets manager; they are in Terraform state.

output "generated_jwt_secret" {
  description = "Auto-generated JWT secret (only shown when not provided via variable)"
  value       = var.jwt_secret == null ? random_password.jwt_secret.result : "(user-supplied)"
  sensitive   = true
}

output "generated_mongo_password" {
  description = "Auto-generated MongoDB password (only shown when not provided via variable)"
  value       = var.mongo_root_password == null && !var.enable_documentdb ? random_password.mongo_password.result : "(user-supplied or managed)"
  sensitive   = true
}

output "generated_redis_password" {
  description = "Auto-generated Redis password (only shown when not provided via variable)"
  value       = var.redis_password == null && !var.enable_elasticache ? random_password.redis_password.result : "(user-supplied or managed)"
  sensitive   = true
}
