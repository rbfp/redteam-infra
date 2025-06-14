#!/bin/bash

#echo "Enter the Bastion IPv6 address:"
#read -r BASTION_IPV6
BASTION_IPV6="2600:1f1c:1a3:9000:4c77:3a22:1544:3f5e"
#echo "Enter the C2 Server IPv4 address:"
#read -r C2_IPV4
C2_IPV4="10.0.140.75"
#echo "Enter the project name (used to locate the PEM file):"
#read -r PROJECT_NAME
PROJECT_NAME="redwesttest"
PEM_FILE="./build/${PROJECT_NAME}-bastion.pem"

if [[ ! -f "$PEM_FILE" ]]; then
  echo "Error: PEM file '$PEM_FILE' not found."
  exit 1
fi

echo "Using PEM file: $PEM_FILE"

# Run Ansible playbook with inline inventory
ansible-playbook -i "$BASTION_IPV6," -u bastion --private-key "$PEM_FILE" ./ans-cob-v4.9.1/playbook.yml -e "c2_ipv4=$C2_IPV4"

