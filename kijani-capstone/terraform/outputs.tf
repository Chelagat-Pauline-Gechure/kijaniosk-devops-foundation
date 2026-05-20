output "namespace_created" {
  description = "The staging namespace provisioned by Terraform"
  value       = kubernetes_namespace.staging.metadata[0].name
}
