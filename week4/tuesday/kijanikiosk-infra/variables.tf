variable "region" {
  description = "GCP/AWS region closest to Nairobi for API server deployment"
  type        = string
  default     = "europe-west1"   # or your chosen region
}

variable "instance_type" {
  description = "VM instance size for KijaniKiosk API server"
  type        = string
  default     = "e2-micro"       # or t2.micro for AWS
}

variable "ssh_key_name" {
  description = "Name of SSH key pair to attach to the instance"
  type        = string
  # No default — must be set explicitly in terraform.tfvars
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}