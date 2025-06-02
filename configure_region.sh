#!/bin/bash

# Get list of profiles from AWS config
profiles=($(aws configure list-profiles))

# Exit if no profiles found
if [ ${#profiles[@]} -eq 0 ]; then
    echo "No AWS profiles found. Run 'aws configure' to set one up."
    exit 1
fi


# Display the profiles with numbers
echo "Select an AWS profile to use:"
for i in "${!profiles[@]}"; do
    echo "$((i+1))) ${profiles[$i]}"
done

# Prompt user to choose
read -p "Enter the number of the profile to use: " choice

# Validate input
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#profiles[@]}" ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

# Set the selected profile
export AWS_PROFILE="${profiles[$((choice-1))]}"
echo "Using profile: $AWS_PROFILE"

# -------- Prompt for Project Name --------
echo "Enter a project name (no spaces):"
read PROJECT_NAME
if [[ -z "$PROJECT_NAME" ]]; then
  echo "[!] Project name cannot be empty. Exiting."
  exit 1
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
AZS=($(aws ec2 describe-availability-zones --region "$REGION" --query 'AvailabilityZones[*].ZoneName' --output text --profile "$AWS_PROFILE"))
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
    --output text --profile redteam)

elif [[ "$OS" == "amazon" ]]; then
  AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" \
              "Name=architecture,Values=x86_64" \
    --region "$REGION" \
    --query 'Images | sort_by(@, &CreationDate)[-1].ImageId' \
    --output text --profile redteam)
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
# sed -i "s/ami-.*\"/\"$AMI_ID\"/g" build/*.tf
sed -i "s/ami *= *\"ami-[a-zA-Z0-9-]*\"/ami = \"$AMI_ID\"/g" build/*.tf

echo "[*] Updating availability zones to $AZ in build/*.tf..."
sed -i "s/availability_zone *= *\"[^\"]*\"/availability_zone = \"$AZ\"/g" build/*.tf

echo "[*] Prefixing resource names with $PROJECT_NAME..."
sed -i "s/\(Name\" *= *\"\)\(.*\)\"/\1$PROJECT_NAME-\2\"/g" build/*.tf

echo "[*] Updating provider.tf region to $REGION..."
sed -i "s/region *= *\"[^\"]*\"/region = \"$REGION\"/g" build/provider.tf

# -------- Generate auto README --------
echo "[*] Writing build/terraform.tfvars..."
cat <<EOF > build/terraform.tfvars
project_name        = "$PROJECT_NAME"
region              = "$REGION"
availability_zone   = "$AZ"
ami_id              = "$AMI_ID"
key_name            = "$KEY_NAME"
ipv6_border_group   = "$REGION"
EOF

echo "[✔] Configuration updated in ./build with region $REGION, AZ $AZ, and AMI $AMI_ID."

# -------- Next Step Instructions --------
echo "[➡] Next steps:"
echo "cd build"
echo "terraform init && terraform plan && terraform apply"

