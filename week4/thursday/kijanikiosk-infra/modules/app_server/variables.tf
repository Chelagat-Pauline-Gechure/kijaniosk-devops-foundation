variable "name" {
  description = "Service name: api, payments, or logs"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the app server"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Deployment environment: staging or production"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for the instance"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name to attach to the instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance into"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "List of CIDR blocks allowed to SSH into the server"
  type        = list(string)
}