output "endpoint" {
  description = "DocumentDB cluster endpoint (empty string if not enabled)"
  value       = var.enable_documentdb ? aws_docdb_cluster.this[0].endpoint : "DocumentDB not enabled"
  sensitive   = true
}
