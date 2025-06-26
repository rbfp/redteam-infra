#!/bin/bash

set -euo pipefail

### INPUT: Project Info ###
#read -p "Enter project name (used for PEM file prefix): " PROJECT_NAME
#read -p "Enter bastion IPv6 address: " BASTION_IP
#read -p "Enter redirector IPv4 address: " REDIRECTOR_IP
#read -p "Enter your Cloudflare API token: " CF_API_TOKEN
#read -p "Enter the domain to use for the tunnel: " TUNNEL_DOMAIN
#
PROJECT_NAME="west1"
BASTION_IP="2600:1f1c:677:d500:4cfd:4354:782f:ab22"
REDIRECTOR_IP="10.0.14.65"
CF_API_TOKEN="6sGiwXWCSbk2QqLvlr7HUKWmxB0dGKzwSxUkVPdh"
TUNNEL_DOMAIN="fmovies4.org"

### Select S3 file for cloudflared .deb download ###
echo "[*] Listing S3 buckets..."
BUCKETS=($(aws s3 ls | awk '{print $3}'))

for i in "${!BUCKETS[@]}"; do
  echo "[$i] ${BUCKETS[$i]}"
done

read -p "Select cloudflared .deb bucket number: " BUCKET_INDEX
S3_BUCKET=${BUCKETS[$BUCKET_INDEX]}

echo "[*] Listing files in s3://$S3_BUCKET/..."
FILES=($(aws s3 ls s3://$S3_BUCKET/ | awk '{print $4}'))

for i in "${!FILES[@]}"; do
  echo "[$i] ${FILES[$i]}"
done

read -p "Select file number (.deb): " FILE_INDEX
S3_KEY=${FILES[$FILE_INDEX]}

### Get correct S3 region for presigned URL ###
AWS_REGION=$(aws s3api get-bucket-location --bucket "$S3_BUCKET" --output text)
if [[ "$AWS_REGION" == "None" ]]; then
  AWS_REGION="us-east-1"
fi

echo "[*] Generating pre-signed URL using region $AWS_REGION..."
DEB_SIGNED_URL=$(aws s3 presign s3://$S3_BUCKET/$S3_KEY --expires-in 300 --region "$AWS_REGION" --endpoint-url https://s3.dualstack.$AWS_REGION.amazonaws.com)
echo "[+] Presigned URL generated."

### SELECT S3 FILE FOR cert.pem  ###
echo "[*] Listing S3 buckets..."
BUCKETS=($(aws s3 ls | awk '{print $3}'))

for i in "${!BUCKETS[@]}"; do
  echo "[$i] ${BUCKETS[$i]}"
done

read -p "Select cert.pem bucket number: " BUCKET_INDEX
S3_BUCKET=${BUCKETS[$BUCKET_INDEX]}

echo "[*] Listing files in s3://$S3_BUCKET/..."
FILES=($(aws s3 ls s3://$S3_BUCKET/ | awk '{print $4}'))

for i in "${!FILES[@]}"; do
  echo "[$i] ${FILES[$i]}"
done

read -p "Select file number (.pem): " FILE_INDEX
S3_KEY=${FILES[$FILE_INDEX]}

### Get correct S3 region for presigned URL ###
AWS_REGION=$(aws s3api get-bucket-location --bucket "$S3_BUCKET" --output text)
if [[ "$AWS_REGION" == "None" ]]; then
  AWS_REGION="us-east-1"
fi

echo "[*] Generating pre-signed URL using region $AWS_REGION..."
PEM_SIGNED_URL=$(aws s3 presign s3://$S3_BUCKET/$S3_KEY --expires-in 300 --region "$AWS_REGION" --endpoint-url https://s3.dualstack.$AWS_REGION.amazonaws.com)
echo "[+] Presigned URL generated."

### Echo script directly onto bastion host and execute remotely ###
echo "[*] Building remote setup script on bastion..."
ssh -i ./build/${PROJECT_NAME}-bastion.pem bastion@${BASTION_IP} 'bash -s' <<EOF
cat <<'EOS' > ~/cloudflare_redirector_setup.sh
#!/bin/bash
set -euo pipefail

CF_API_TOKEN="$CF_API_TOKEN"
TUNNEL_NAME="${PROJECT_NAME}-c2-tunnel"
TUNNEL_DOMAIN="$TUNNEL_DOMAIN"

CLOUDFLARED_DIR="/home/redirector/.cloudflared"
mkdir /home/redirector/.cloudflared
mv /home/redirector/cert.pem /home/redirector/.cloudflared/

cloudflared tunnel create "\$TUNNEL_NAME"
TUNNEL_ID=\$(basename "\$CLOUDFLARED_DIR"/*.json)
TUNNEL_ID="\${TUNNEL_ID%.json}"
echo "Tunnel ID: \$TUNNEL_ID"

cat <<EOF2 > "\$CLOUDFLARED_DIR/config.yml"
tunnel: \$TUNNEL_ID
credentials-file: \$CLOUDFLARED_DIR/\$TUNNEL_ID.json

protocol: http2
no-autoupdate: true
edge-ip-version: 6

ingress:
  - hostname: \$TUNNEL_DOMAIN
    service: https://localhost:443
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF2

echo "Setup complete. To run tunnel:"
echo "cloudflared --no-autoupdate --protocol http2 --edge-ip-version 6 tunnel run \"\$TUNNEL_NAME\""
EOS

chmod +x ~/cloudflare_redirector_setup.sh
wget -O cloudflared.deb "$DEB_SIGNED_URL"
wget -O cert.pem "$PEM_SIGNED_URL"
chmod 600 cert.pem

scp -i .ssh/internal.pem -o StrictHostKeyChecking=no cloudflare_redirector_setup.sh cloudflared.deb cert.pem redirector@${REDIRECTOR_IP}:~

ssh -i .ssh/internal.pem -o StrictHostKeyChecking=no redirector@${REDIRECTOR_IP} "sudo dpkg -i ~/cloudflared.deb && ./cloudflare_redirector_setup.sh"


EOF

