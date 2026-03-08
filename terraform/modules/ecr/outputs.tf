output "client_repository_url" {
  description = "ECR URL for the client image"
  value       = aws_ecr_repository.this["client"].repository_url
}

output "server_repository_url" {
  description = "ECR URL for the server image"
  value       = aws_ecr_repository.this["server"].repository_url
}

output "repository_urls" {
  description = "Map of all repository URLs keyed by name"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}
