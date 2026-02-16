#!/bin/bash

echo "Enter the Bastion IPv6 address:"
read -r BASTION_IPV6
echo "Enter the C2 Server IPv4 address:"
read -r C2_IPV4
echo "Enter the Redirector IPv4 address:"
read -r RE_IPV4
echo "Enter the project name (used to locate the PEM file):"
read -r PROJECT_NAME

PEM_FILE="./build/${PROJECT_NAME}-bastion.pem"

if [[ ! -f "$PEM_FILE" ]]; then
  echo "Error: PEM file '$PEM_FILE' not found."
  exit 1
fi

echo "Using PEM file: $PEM_FILE"

# Run Ansible playbook with inline inventory
ansible-playbook -i "$BASTION_IPV6," -u bastion --private-key "$PEM_FILE" ./ans-cob-v4.9.1/playbook.yml -e "c2_ipv4=$C2_IPV4" -e "re_ipv4=$RE_IPV4" 

