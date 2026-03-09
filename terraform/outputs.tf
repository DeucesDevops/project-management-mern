###############################################################################
# Outputs
###############################################################################

# ── VPC ──────────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

# ── EKS ──────────────────────────────────────────────────────────────────────
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC provider URL for IRSA"
  value       = module.eks.cluster_oidc_issuer_url
}

output "configure_kubectl" {
  description = "Run this command to configure kubectl for the cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# ── ECR ──────────────────────────────────────────────────────────────────────
output "ecr_client_repository_url" {
  description = "URL of the client ECR repository"
  value       = module.ecr.client_repository_url
}

output "ecr_server_repository_url" {
  description = "URL of the server ECR repository"
  value       = module.ecr.server_repository_url
}

output "ecr_registry" {
  description = "ECR registry URL (without repository name)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# ── DocumentDB ────────────────────────────────────────────────────────────────
output "docdb_endpoint" {
  description = "DocumentDB cluster endpoint (if enabled)"
  value       = module.documentdb.endpoint
  sensitive   = true
}

# ── ElastiCache ───────────────────────────────────────────────────────────────
output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint (if enabled)"
  value       = module.elasticache.primary_endpoint_address
  sensitive   = true
}

# ── IAM ──────────────────────────────────────────────────────────────────────
output "alb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller"
  value       = module.eks.alb_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for the Cluster Autoscaler"
  value       = module.eks.cluster_autoscaler_role_arn
}
