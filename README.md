# Red Team Infrastructure (Terraform + AWS)

This repo contains a fully Terraform-managed AWS deployment for red team operations. It supports standing up infrastructure for redirectors, C2 servers, bastion hosts, and more — all reproducible, configurable, and automated. Full walkthrough on my blog: https://www.cyberforks.com/automating-red-team-infrastructure

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
- An Attack Box (operator box e.g., Kali Linux)


## 🚀 Deployment Instructions

```bash
# Step 0
git clone git@github.com:rbfp/redteam-infra.git
cd redteam-infra

# Step 1
# Configure your AWS CLI profile. Need AWS permissions to create Access Keys.
# Note the Profile name your choose, otherwise it's just Default
aws configure

# Step 2
# Run through the setup script to deploy to a Region you want
# Note the project name you pick
# -----Creates the following w/ Terraform:
# aws_instance.bastion_host
# aws_instance.c2_server
# aws_instance.redirector
# aws_internet_gateway.gw
# aws_key_pair.bastion_keypair
# aws_key_pair.internal_keypair
# aws_route_table.private_ipv4_only
# aws_route_table.public_ipv6_only
# aws_route_table_association.private_ipv4_only_assoc
# aws_route_table_association.public_ipv6_only_assoc
# aws_security_group.bastion_sg
# aws_security_group.private_sg
# aws_security_group.public_sg
# aws_security_group_rule.private_sg_rules_ingress_bastion_to_private_22
# aws_security_group_rule.private_sg_rules_ingress_bastion_to_private_50050
# aws_security_group_rule.private_sg_rules_ingress_private_to_private_allports
# aws_security_group_rule.private_sg_rules_ingress_public_to_private_443
# aws_security_group_rule.public_sg_rules_egress
# aws_security_group_rule.public_sg_rules_ingress_bastion_to_public_22
# aws_security_group_rule.public_sg_rules_ingress_ipv6_to_public_443
# aws_security_group_rule.public_sg_rules_ingress_ipv6_to_public_80
# aws_security_group_rule.public_sg_rules_ingress_private_to_public_443
# aws_security_group_rule.public_sg_rules_ingress_private_to_public_80
# aws_subnet.private_subnet
# aws_subnet.public_subnet
# aws_vpc.main
# local_file.bastion_private_key
# local_file.internal_private_key
# tls_private_key.key1_local_to_bastion
# tls_private_key.key2_bastion_to_internal
# ----------
# Creates a bastion user on Bastion Host that ssh w/ {{ project_name }}-bastion.pem
./infra_setup.sh

# Step 3
# Verify your AWS resources are running with manage_aws.sh > option 2 > [type your region]
# Verify you can ssh into your bastion host with the key in redteam_infra/build/{{ project_name }}-bastion.pem
./manage_aws.sh
ssh -i redteam_infra/build/{{ project_name }}-bastion.pem bastion@{{ bastion_ipv6 }}

# Step 4
# Set up Cobalt Strike or C2 of choice, this will also configure your redirector for CS
# PreRequisites:
## 1) Host your own CobaltStrike file and replace the link in playbook.yml with your link
## 2) Should be a 7z file
## 3) Password protect your public Cobaltstrike 7z file
./cobalt_setup.sh

# Step 5
# Connect CobaltStrike(CS) Client to CS Server 
# (this is specific to my CS setup)
## 1) ssh to Bastion > ssh to C2 Server
## 2) in the C2 Server run:
chmod +x ~/CS491/Server/teamserver ~/CS491/Server/TeamServerImage
~/CS491/Server/teamserver {{ c2_ipv4 }} {{ cobalt_server_pass }}
## [note] you pick the {{ cobalt_server_pass }}
## [note] leave open or CS server will shutdown
## 3) on your attack box, open a new terminal and run:
ssh -i {{ project_name }}-bastion.pem -L 50050:{{ c2_ipv4 }}:50050 bastion@{{bastion-ipv6}}
## [note] ssh proxy to connect your attack box to your c2 server
## [note] leave open or your CS client won't talk to your CS server
## 4) on your attack box, open a new terminal
## 6) ssh to bastion > ssh to redirector
## 7) in your Redirector run:
sudo socat TCP6-LISTEN:443,reuseaddr,fork TCP4:{{ c2_ipv4}}:443
## [note] redirects ipv6 traffic to C2 Server (ipv4)
## [note] leave open or your beacons won't talk to your CS server
## 8) Download & extract the CobaltStrike 7zip onto your Attack Box then run:
chmod +x ~/CS491/Client/cobaltstrike-client.sh
## 9) open a new terminal and run:
./cobaltstrike-client.sh
## 12) Fill in:
## 12a) Alias: rbfp@{{ project_name }}
## 12b) Host: 127.0.0.1
## 12c) Port: 50050
## 12d) User: rbfp
## 12e) Password: {{ cobalt_server_pass }}
