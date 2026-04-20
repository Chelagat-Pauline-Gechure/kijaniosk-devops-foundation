variable "region" {
  description = "AWS region closest to Nairobi for infrastructure deployment"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type for KijaniKiosk app servers"
  type        = string
  default     = "t2.micro"
}

variable "ssh_key_name" {
  description = "Name of SSH key pair to attach to instances"
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

variable "ssh_allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH into the app servers"
  type        = list(string)
}