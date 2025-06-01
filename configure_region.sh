#!/bin/bash

# -------- AWS Credential Check --------
if ! aws sts get-caller-identity &>/dev/null; then
  echo "[!] AWS credentials not found or expired."
  echo "    Launching 'aws configure'..."
  aws configure

  # Re-check after configuration
  if ! aws sts get-caller-identity &>/dev/null; then
    echo "[!] AWS CLI is still not configured. Exiting."
    exit 1
  fi
else
  echo "[✔] AWS credentials detected."
fi

# -------- Available Options --------
REGIONS=("us-east-1" "us-east-2" "us-west-1" "us-west-2")
OS_OPTIONS=("ubuntu" "amazon")

# -------- Prompt for Region --------
echo "Select AWS region:"
select REGION in "${REGIONS[@]}"; do
  [[ -n "$REGION" ]] && break
  echo "Invalid selection. Try again."
done

# -------- Prompt for OS --------
echo "Select OS image:"
select OS in "${OS_OPTIONS[@]}"; do
  [[ -n "$OS" ]] && break
  echo "Invalid selection. Try again."
done

# -------- Prompt for Availability Zone --------
echo "Fetching availability zones for $REGION..."
AZS=($(aws ec2 describe-availability-zones --region "$REGION" --query 'AvailabilityZones[*].ZoneName' --output text))
echo "Select availability zone:"
select AZ in "${AZS[@]}"; do
  [[ -n "$AZ" ]] && break
  echo "Invalid selection. Try again."
done

# -------- Validate Selection --------
if [[ -z "$REGION" || -z "$OS" || -z "$AZ" ]]; then
  echo "[!] Missing required input."
  exit 1
fi

# -------- Get AMI ID --------
echo "[*] Looking up latest AMI for $OS in $REGION..."

if [[ "$OS" == "ubuntu" ]]; then
  AMI_ID=$(aws ec2 describe-images \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
              "Name=virtualization-type,Values=hvm" \
              "Name=architecture,Values=x86_64" \
    --region "$REGION" \
    --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
    --output text)

elif [[ "$OS" == "amazon" ]]; then
  AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" \
              "Name=architecture,Values=x86_64" \
    --region "$REGION" \
    --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
    --output text)
else
  echo "[!] Unsupported OS type."
  exit 1
fi

if [[ -z "$AMI_ID" ]]; then
  echo "[!] Failed to fetch AMI."
  exit 1
fi

echo "[+] Using AMI: $AMI_ID"

# -------- Create build directory --------
echo "[*] Preparing build/ directory..."
mkdir -p build
cp *.tf build/

# -------- Update Files in build --------
echo "[*] Updating AMIs in build/*.tf..."
sed -i "s/ami-.*\"/\"$AMI_ID\"/g" build/*.tf

echo "[*] Updating availability zones to $AZ in build/*.tf..."
sed -i "s/availability_zone *= *\"[^\"]*\"/availability_zone = \"$AZ\"/g" build/*.tf

# -------- Generate auto README --------
echo "[*] Writing build/README.auto.md..."
cat <<EOF > build/README.auto.md
# Terraform Config Summary

**Region:** $REGION  
**Availability Zone:** $AZ  
**Operating System:** $OS  
**AMI ID:** $AMI_ID

Generated automatically by configure_region.sh
EOF

echo "[✔] Configuration updated in ./build with region $REGION, AZ $AZ, and AMI $AMI_ID."

# -------- Next Step Instructions --------
echo "\n[➡] Next steps:"
echo "cd build"
echo "terraform init"
echo "terraform plan"
echo "terraform apply"

