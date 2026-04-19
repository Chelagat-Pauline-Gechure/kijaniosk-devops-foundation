# Manual Provisioning Decisions - KijaniKiosk API Server

| Decision          | Value I chose | Reason |
|-------------------|---------------|--------|
| Cloud provider    | GCP | Selected for regional availability and free-tier offerings. |
| Region            | [us-west1 | Selected since free tier is available in this region |
| Operating system  | Ubuntu 24.04 LTS* | *Note: Lab requested 22.04, but 24.04 was selected during manual boot disk configuration. |
| Instance type     | e2-micro | Selected to minimize operational costs while meeting the lab's free-tier requirement. |
| VPC               | default | Used the default GCP network for simplicity during initial staging. |
| Subnet            | default | Inherited from the selected region. |
| Security group    | Custom VPC Firewall | Configured to allow SSH (22) from my specific IP only and HTTP (80) from 0.0.0.0/0 to meet access constraints. |
| SSH key pair      | key_filename | Generated a new ED25519/RSA key specifically for secure GCP access. |
| Root volume size  | 10 GB | Kept the default minimum size to stay within free-tier limits. |
| Public IP?        | Yes (Ephemeral) | Required to SSH into the machine and test HTTP access externally. |
| Tags / labels     | staging, api | Used to identify the environment and role of the instance. |