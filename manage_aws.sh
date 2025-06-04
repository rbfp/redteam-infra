#!/bin/bash

while true; do
  # Display menu options
  echo "\nSelect an action:"
  echo "1) List all EC2 instances in all regions"
  echo "2) List EC2 instances by region"
  echo "3) Describe VPCs"
  echo "4) Start EC2 instances by region"
  echo "5) Start EC2 instances by ID"
  echo "6) Stop all running EC2 instances"
  echo "7) Stop all EC2 instances by region"
  echo "8) Stop EC2 instances by ID"
  echo "9) Exit"

  # Prompt user for choice
  read -p "Enter your choice: " choice

  # Act on user input
  case "$choice" in
    1)
      echo "Running: List all EC2 instances in all regions"
      for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
        echo "Region: $region"
        aws ec2 describe-instances --region "$region" \
          --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name']|[0].Value, State.Name, InstanceType, PrivateIpAddress, PublicIpAddress, Ipv6Addresses[0].Ipv6Address]" \
          --output table
      done
      ;;
    2)
      echo "Running: List EC2 Instances by Region"
      read -p "Enter region (e.g., us-east-1): " region
      aws ec2 describe-instances --region "$region" \
        --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name']|[0].Value, State.Name, InstanceType, PrivateIpAddress, PublicIpAddress, Ipv6Addresses[0].Ipv6Address]" \
        --output table
      ;;
    3)
      echo "Running: Describe VPCs"
      for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
        echo "Region: $region"
        aws ec2 describe-vpcs --region "$region" \
          --query "Vpcs[*].[VpcId,State,CidrBlock,IsDefault]" \
          --output table
      done
      ;;
    4)
      echo "Running: Start EC2 Instances by Region"
      read -p "Enter region (e.g., us-east-1): " region
      echo "Checking for stopped instances in $region..."
      instance_info=$(aws ec2 describe-instances --region "$region" \
        --filters Name=instance-state-name,Values=stopped \
        --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='Name']|[0].Value]" --output text)
      if [ -n "$instance_info" ]; then
        while read -r instance_id name; do
          if [[ "$name" == "Redirector" ]]; then
            echo "Found stopped Redirector ($instance_id). Redeploying with Terraform..."
            export TF_VAR_region="$region"
            terraform destroy -target=aws_instance.redirector -var="region=$region" -auto-approve
            terraform apply -target=aws_instance.redirector -var="region=$region" -auto-approve
          else
            echo "Starting instance $instance_id ($name) in $region"
            aws ec2 start-instances --region "$region" --instance-ids "$instance_id"
          fi
        done <<< "$instance_info"
      else
        echo "No stopped instances found in $region."
        read -p "Are you trying to start a Redirector instance? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          echo "Redirector must be deployed via Terraform. Running Terraform commands..."
          export TF_VAR_region="$region"
          terraform init && terraform apply -target=aws_instance.redirector -var="region=$region" -auto-approve
        fi
      fi
      ;;
    5)
      echo "Running: Start EC2 Instances by ID"
      read -p "Enter region (e.g., us-east-1): " region
      read -p "Enter instance IDs separated by space: " instance_ids
      if [ -n "$instance_ids" ]; then
        echo "Starting instances: $instance_ids in region: $region"
        aws ec2 start-instances --region "$region" --instance-ids $instance_ids
      else
        echo "No instance IDs provided."
      fi
      ;;
    6)
      echo "Running: Stop all running EC2 instances"
      for region in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do
        echo "Checking region: $region"
        instance_ids=$(aws ec2 describe-instances --region "$region" \
          --filters Name=instance-state-name,Values=running \
          --query "Reservations[].Instances[].InstanceId" --output text)
        if [ -n "$instance_ids" ]; then
          echo "Stopping instances in $region: $instance_ids"
          aws ec2 stop-instances --region "$region" --instance-ids $instance_ids
        else
          echo "No running instances found in $region"
        fi
      done
      ;;
    7)
      echo "Running: Stop all EC2 Instances by Region"
      read -p "Enter region (e.g., us-east-1): " region
      instance_ids=$(aws ec2 describe-instances --region "$region" \
        --filters Name=instance-state-name,Values=running \
        --query "Reservations[].Instances[].InstanceId" --output text)
      if [ -n "$instance_ids" ]; then
        echo "Stopping all running instances in $region: $instance_ids"
        aws ec2 stop-instances --region "$region" --instance-ids $instance_ids
      else
        echo "No running instances found in $region"
      fi
      ;;
    8)
      echo "Running: Stop EC2 Instances by ID"
      read -p "Enter region (e.g., us-east-1): " region
      read -p "Enter instance IDs separated by space: " instance_ids
      if [ -n "$instance_ids" ]; then
        echo "Stopping instances: $instance_ids in region: $region"
        aws ec2 stop-instances --region "$region" --instance-ids $instance_ids
      else
        echo "No instance IDs provided."
      fi
      ;;
    9)
      echo "Exiting."
      break
      ;;
    *)
      echo "Invalid option. Please enter a number between 1 and 9."
      ;;
  esac

done

