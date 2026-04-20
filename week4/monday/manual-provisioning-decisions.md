# Manual Provisioning Decisions - KijaniKiosk API Server

| Decision          | Value I chose | Reason |
|-------------------|---------------|--------|
| Cloud provider    | AWS | Selected to utilize standard industry tooling and EC2 free tier. |
| Region            | eu-west-1 (Ireland) | Closest stable region providing good latency to Nairobi, Kenya. |
| Operating system  | Ubuntu 22.04 LTS | Standardized OS requirement for KijaniKiosk. |
| Instance type     | t2.micro | Smallest Free Tier eligible instance to minimize project costs. |
| VPC               | Default VPC | Used the default AWS network for simplicity during initial staging. |
| Subnet            | No preference | Allowed AWS to assign a default availability zone. |
| Security group    | kijanikiosk-sg | Configured to allow SSH (22) from my specific IP only and HTTP (80) from 0.0.0.0/0. |
| SSH key pair      | kijanikiosk-aws | Generated a new RSA .pem key for secure identity-based access. |
| Root volume size  | 8 GB (gp2) | Kept the default AWS minimum size to stay within free-tier limits. |
| Public IP?        | Yes (Auto-assigned) | Required to SSH into the machine and test HTTP access externally. |
| Tags / labels     | Name: kijanikiosk-api-staging | Used to identify the environment and role of the instance in the EC2 console. |