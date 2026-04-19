# KijaniKiosk API Server - Desired State Specification

## Identity
- **Name:** kijanikiosk-api-staging
- **Environment tag:** staging 
- **Owner tag:** amina 

## Compute
- **Provider:** AWS 
- **Region:** eu-west-1 (Ireland)
- **Instance type:** t2.micro 
- **Operating system:** ubuntu-24.04-lts (Noble)

## Networking
- **VPC:** vpc-172-31-0-0/16 (Default VPC)
- **Subnet:** subnet-172.31.47.0/20
- **Assign public IP:** yes

## Access Control
- **SSH access:** port 22, source 41.90.208.21532 only
- **HTTP access:** port 80, source 0.0.0.0/0
- **All other inbound:** deny 
- **All outbound:** allow

## Storage
- **Root volume:** 8GB, type gp2 (General Purpose SSD) 

## Authentication
- **SSH key pair name:** kijanikiosk-aws 

## What must NOT exist on this server after provisioning
- No default password authentication 
- No services listening other than sshd 
- No world-writable directories outside /tmp 

## Open questions
- Should we use a Data Source to find the most recent Ubuntu AMI ID instead of hardcoding it?
- Do we need to assign a Static (Elastic) IP if we plan to use this for a production load balancer? 

## Hardest Decision and Why
The hardest decision was choosing the correct **Security Group** source for SSH access. Restricting it to my specific IP is more secure but risky if my local IP changes (dynamic IP).I chose "My IP" to align with a professional security posture that blocks global access to port 22. 