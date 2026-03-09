output "primary_endpoint_address" {
  description = "ElastiCache Redis primary endpoint (empty string if not enabled)"
  value       = var.enable_elasticache ? aws_elasticache_replication_group.this[0].primary_endpoint_address : "ElastiCache not enabled"
  sensitive   = true
}
