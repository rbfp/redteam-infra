# Red Team Infrastructure (Terraform + AWS)

This repo contains a fully Terraform-managed AWS deployment for red team operations. It supports standing up infrastructure for redirectors, C2 servers, phishing servers, and more — all reproducible, configurable, and automated.

---

## 🧩 Components

- **Redirector**: For traffic forwarding and domain fronting
- **C2 Server**: Beacon receiver and staging infrastructure (e.g., Mythic, Cobalt Strike, etc.)
- **Bastion Host**: Secure SSH gateway for operational access
- **Security Groups**: Locked down with configurable ingress rules
- **VPC + Subnets**: Isolated networking for red team infrastructure

---

## 🚀 Deployment Instructions

```bash
git clone git@github.com:<your-username>/redteam-infra.git
cd redteam-infra

# Configure your AWS CLI profile
aws configure --profile redteam

# Initialize and apply Terraform
terraform init
terraform plan
terraform apply

