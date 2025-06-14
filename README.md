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
git clone git@github.com:rbfp/redteam-infra.git
cd redteam-infra

# Step 1
# Configure your AWS CLI profile. Need AWS permissions to create Access Keys.
aws configure

# Step 2
# Run through the helper script to identify the Region you want to build your infrastructure
./configure_region.sh

# Step 3
# Verify your AWS resources are running with manage_aws.sh > option 2 > [type your region]
./manage_aws.sh

# Step 4
# Set up Cobalt Strike or C2 of choice
# PreRequisites:
## 1) Host and replace the cobalstrike file
## 2) Should be a 7z file
## 3) Password protect your public Cobaltstrike 7z file

./cobalt_setup.sh
