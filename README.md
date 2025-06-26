# Red Team Infrastructure (Terraform + Ansible + AWS + Cloudflare)

This repo contains a fully Terraform-managed Ansible-configured AWS deployment for red team operations. It supports standing up infrastructure for Cloudflare redirectors, C2 servers, bastion hosts, and more — all reproducible, configurable, and automated. Full walkthrough on my blog: https://www.cyberforks.com/automating-red-team-infrastructure

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
- sudo apt install terraform, ansible, awscli, cloudflared
```
- An Attack Box (operator box e.g., Kali Linux)
- An AWS account where you can create Access Keys to configure AWS CLI
- A Cloudflare account where you can create API keys


## 🚀 Deployment Instructions

```bash
# Step 0
# Configure your AWS CLI profile.
# Need AWS permissions to create Access Keys and will need the Access Key and Secret Key.
# Configure your Cloudflare setup.
# Need to create an API Token and save for later steps.
git clone git@github.com:rbfp/redteam-infra.git
cd redteam-infra
aws configure
cloudflared login


# Step 1
# Run through the setup script to deploy to a Region you select
# Note the project name you pick
# Creates: (Resource) - (Username) - (Key to use)
# Bastion Host - bastion - {project_name}-bastion.pem
# Redirector - redirector - internal.pem
# C2 Server - c2server - internal.pem
# The [Redirector] and [C2 Server] can only be ssh-ed from w/n the [Bastion Host]
./1_infra_setup.sh

# Step 2
# Verify your AWS resources are running with manage_aws.sh > option 2 > [type your region]
# Verify you can ssh into your bastion host with the key in redteam_infra/build/{{ project_name }}-bastion.pem
./0_manage_aws.sh
ssh -i ./redteam_infra/build/{{ project_name }}-bastion.pem bastion@{{ bastion_ipv6 }}

# Step 3
# Set up Cloudflare redirector
./2_cloudflare_setup.sh

# Step 4
# Set up Cobalt Strike or C2 of choice, this will also configure your redirector for CS
# PreRequisites:
## 1) Host your own CobaltStrike file and replace the link in playbook.yml with your link
## 2) Should be a 7z file
## 3) Password protect your public Cobaltstrike 7z file
./3_cobalt_setup.sh

# Step 5
# Connect CobaltStrike(CS) Client to CS Server 
# ssh to Bastion then ssh to C2 Server
# You pick the {{ cobalt_server_pass }}
# Leave terminal open or CS server will shutdown
# In the C2 Server run:
chmod +x ~/CS491/Server/teamserver ~/CS491/Server/TeamServerImage
~/CS491/Server/teamserver {{ c2_ipv4 }} {{ cobalt_server_pass }}

# Set up ssh proxy to connect your attack box to your c2 server
# Leave open or your CS client won't talk to your CS server
# On your attack box, open a new terminal and run:
ssh -i {{ project_name }}-bastion.pem -L 50050:{{ c2_ipv4 }}:50050 bastion@{{bastion-ipv6}}

# Redirect IPv6 traffic hitting Redirector to C2 Server
# Leave terminal open or your beacons won't talk to your CS server
# On your attack box, open a new terminal
# ssh to bastion then ssh to redirector
# In your Redirector run:
sudo socat TCP6-LISTEN:443,reuseaddr,fork TCP4:{{ c2_ipv4}}:443

# Run Cloudflare Tunneling to mask your IPv6 address
# Leave terminal open or your Cloudflare tunnel will close
# On your attack box, open a new terminal
# ssh into your Bastion then ssh into your Redirector
# In your Redirector run:
cloudflared --no-autoupdate --protocol http2 --edge-ip-version 6 tunnel run "{{ project_name }}-c2-tunnel"

# Download & extract the CobaltStrike 7zip onto your Attack Box then run:
chmod +x ~/CS491/Client/cobaltstrike-client.sh

# Open a new terminal and run:
./CS491/Client/cobaltstrike-client.sh
## Fill in:
## Alias: rbfp@{{ project_name }}
## Host: 127.0.0.1
## Port: 50050
## User: rbfp
## Password: {{ cobalt_server_pass }}
