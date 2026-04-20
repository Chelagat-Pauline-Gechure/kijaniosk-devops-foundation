terraform {
  backend "s3" {
    bucket         = "kijanikiosk-terraform-state-chela"
    key            = "friday/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "kijanikiosk-tf-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  servers = {
    api = {
      instance_type = "t2.micro"
    }
    payments = {
      instance_type = "t2.micro"
    }
    logs = {
      instance_type = "t2.micro"
    }
  }
}

module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name             = each.key
  instance_type    = each.value.instance_type
  environment      = var.environment
  ami_id           = data.aws_ami.ubuntu_2204.id
  key_name         = var.ssh_key_name
  subnet_id        = data.aws_subnets.default.ids[0]
  vpc_id           = data.aws_vpc.default.id
  ssh_allowed_cidr = var.ssh_allowed_cidr_blocks
}