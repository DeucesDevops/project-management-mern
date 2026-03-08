output "namespace" {
  description = "Kubernetes namespace where all app resources are deployed"
  value       = kubernetes_namespace_v1.app.metadata[0].name
}

output "ingress_hostname" {
  description = "ALB hostname assigned to the ingress (available after the LB is provisioned)"
  value       = try(kubernetes_ingress_v1.app.status[0].load_balancer[0].ingress[0].hostname, "pending")
}

output "server_service_name" {
  value = kubernetes_service_v1.server.metadata[0].name
}

output "client_service_name" {
  value = kubernetes_service_v1.client.metadata[0].name
}
