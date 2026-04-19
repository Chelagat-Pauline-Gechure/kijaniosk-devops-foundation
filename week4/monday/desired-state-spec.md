# KijaniKiosk API Server - Desired State Specification

## Identity
- Name: kijanikiosk-api-staging
- Environment tag: staging
- Role tag: api
- Owner tag: amina

## Compute
- Provider: GCP
- Region: us-west1
- Instance type: e2-micro
- Operating system: ubuntu-24.04-lts (exact image family: ubuntu-2404-lts / project: ubuntu-os-cloud)

## Networking
- VPC: default
- Subnet: default
- Assign public IP: yes (ephemeral)

## Access Control
- SSH access: port 22, source 41.90.208.215/32 only
- HTTP access: port 80, source 0.0.0.0/0
- All other inbound: deny
- All outbound: allow

## Storage
- Root volume: 10GB, type pd-standard (Standard Persistent Disk)

## Authentication
- SSH key pair name: key_filename (associated with user chela)

## What must NOT exist on this server after provisioning
- No default password authentication
- No services listening other than sshd
- No world-writable directories outside /tmp

## Open questions (things that will need decisions before Terraform can encode this)
- How do we dynamically fetch the most recent Ubuntu 24.04 LTS image ID in Terraform so we don't have to hardcode a specific release date?
- Relying on the `default` VPC is fine for manual staging, but should we explicitly define and manage a custom VPC and Subnet in Terraform to ensure proper network isolation?
- In GCP, should we attach the firewall rules directly to the instance using "Network Tags", or use a service account identity for the firewall targeting?

## Hardest Decision and Why
The hardest decision during manual provisioning was configuring the Security Group equivalent (VPC Firewall rules) and tying them to the instance. Unlike AWS, where I can attach a specific Security Group directly to an EC2 instance on the creation screen, GCP relies on VPC-wide firewall rules that filter traffic based on Network Tags or Service Accounts. I was least certain about whether to globally apply the rule or strictly tag this single instance to ensure the 41.90.208.215/32 SSH restriction didn't accidentally lock out or expose other potential resources in the default VPC. This will require explicit definition when moving to Terraform to ensure the firewall rule only targets the KijaniKiosk API server.