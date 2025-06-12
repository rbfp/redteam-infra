#!/bin/bash

echo "Enter the Bastion IPv6 address:"
read -r BASTION_IPV6

echo "Enter the project name (used to locate the PEM file):"
read -r PROJECT_NAME

PEM_FILE="../build/${PROJECT_NAME}-bastion.pem"

if [[ ! -f "$PEM_FILE" ]]; then
  echo "Error: PEM file '$PEM_FILE' not found."
  exit 1
fi

echo "Using PEM file: $PEM_FILE"

# Run Ansible playbook with inline inventory
ansible-playbook -i "$BASTION_IPV6," -u bastion --private-key "$PEM_FILE" playbook.yml

