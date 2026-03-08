output "endpoint" {
  description = "DocumentDB cluster writer endpoint"
  value       = aws_docdb_cluster.this.endpoint
  sensitive   = true
}

output "reader_endpoint" {
  description = "DocumentDB cluster reader endpoint"
  value       = aws_docdb_cluster.this.reader_endpoint
  sensitive   = true
}

output "port" {
  value = aws_docdb_cluster.this.port
}

output "master_username" {
  value = aws_docdb_cluster.this.master_username
}

output "master_password_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master password"
  value       = aws_secretsmanager_secret.docdb_password.arn
}

output "master_password" {
  value     = random_password.master.result
  sensitive = true
}
