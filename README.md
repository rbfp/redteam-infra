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
./infra_setup.sh

# Step 3
# Verify your AWS resources are running with manage_aws.sh > option 2 > [type your region]
./manage_aws.sh

# Step 4
# Set up Cobalt Strike or C2 of choice, this will also configure your redirector for CS
# PreRequisites:
## 1) Host your own CobaltStrike file and replace the link in the yml with your link
## 2) Should be a 7z file
## 3) Password protect your public Cobaltstrike 7z file
./cobalt_setup.sh

# Step 5
# Connect CS Client to CS Server [this is specific to my CS files may not apply to others]
## 1) SSH to Bastion > SSH to C2teamser
## 2) chmod +x ~/CS491/Server/teamserver ~/CS491/Server/TeamServerImage
## 3) ~/CS491/Server/teamserver [C2_IPV4] [SET A PASSWORD]
## 4) Download the CobaltStrike 7zip onto your Attack Box
## 5) chmod +x ~/CS491/Client/cobaltstrike-client.sh
## 6) ssh -i {{ project_name }}-bastion.pem -L 50050:{{ c2_ipv4 }}:50050 bastion@{{bastion-ipv6}}
## 7) new terminal
## 8) ./cobaltstrike-client.sh
## 9) Fill in:
##       Alias: rbfp@{{ project_name }}
##        Host: 127.0.0.1
##        Port: 50050
##        User: rbfp
##    Password: {{ password }}
