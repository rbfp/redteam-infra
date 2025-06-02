# Red Team Infrastructure (Terraform + AWS)

This repo contains a fully Terraform-managed AWS deployment for red team operations. It supports standing up infrastructure for redirectors, C2 servers, bastion hosts, and more — all reproducible, configurable, and automated.

---

## 🧩 Components

- **Redirector**: For traffic forwarding and domain fronting
- **C2 Server**: Beacon receiver and staging infrastructure (e.g., Mythic, Cobalt Strike, etc.)
- **Bastion Host**: Secure SSH gateway for operational access
- **Security Groups**: Locked down with configurable ingress rules
- **VPC + Subnets + Route Tables**: Isolated networking for red team infrastructure
- **SSH Key**: Private keys created and deployed into EC2 for use

---

## Pre-requisites
```bash
- sudo apt update
- sudo apt install terraform
- sudo apt install awscli
```
- An AWS account where you can create Access Keys to configure AWS CLI 


## 🚀 Deployment Instructions

```bash
# Step 0
git clone git@github.com:<your-username>/redteam-infra.git
cd redteam-infra

# Step 1
# Configure your AWS CLI profile. Need AWS permissions to create Access Keys.
aws configure

# Step 2
# Run through the helper script to identify the Region you want to build your infrastructure
./configure_region.sh

# Step 3
# Once the script is completed, you'll see instructions to run the following in your terminal. Type "yes" when prompted.
[➡] Next steps:
cd build
terraform init && terraform plan && terraform apply

# Step 4
# Upon completion you'll see
Apply complete! Resources: 30 added, 0 changed, 0 destroyed.
