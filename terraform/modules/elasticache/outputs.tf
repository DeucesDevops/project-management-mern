output "primary_endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
  sensitive   = true
}

output "port" {
  value = 6379
}

output "auth_token" {
  description = "Redis AUTH token"
  value       = random_password.auth_token.result
  sensitive   = true
}

output "auth_token_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the auth token"
  value       = aws_secretsmanager_secret.redis_auth.arn
}

output "redis_url" {
  description = "Full Redis connection URL"
  value       = "rediss://:${random_password.auth_token.result}@${aws_elasticache_replication_group.this.primary_endpoint_address}:6379"
  sensitive   = true
}
