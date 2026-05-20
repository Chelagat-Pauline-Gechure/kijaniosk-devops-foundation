terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = var.staging_namespace
    labels = {
      environment = "staging"
      managed-by  = "terraform"
    }
  }
}

output "staging_namespace" {
  value = kubernetes_namespace.staging.metadata[0].name
}
