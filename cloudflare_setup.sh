#!/bin/bash

set -euo pipefail

### INPUT: Project Info ###
read -p "Enter project name (used for PEM file prefix): " PROJECT_NAME
read -p "Enter bastion IPv6 address: " BASTION_IP

### ☁️ Select S3 file for cloudflared .deb download ###
echo "[*] Listing S3 buckets..."
BUCKETS=($(aws s3 ls | awk '{print $3}'))

for i in "${!BUCKETS[@]}"; do
  echo "[$i] ${BUCKETS[$i]}"
done

read -p "Select bucket number: " BUCKET_INDEX
S3_BUCKET=${BUCKETS[$BUCKET_INDEX]}

echo "[*] Listing files in s3://$S3_BUCKET/..."
FILES=($(aws s3 ls s3://$S3_BUCKET/ | awk '{print $4}'))

for i in "${!FILES[@]}"; do
  echo "[$i] ${FILES[$i]}"
done

read -p "Select file number (.deb): " FILE_INDEX
S3_KEY=${FILES[$FILE_INDEX]}

###  Get correct S3 region for presigned URL ###
AWS_REGION=$(aws s3api get-bucket-location --bucket "$S3_BUCKET" --output text)
if [[ "$AWS_REGION" == "None" ]]; then
  AWS_REGION="us-east-1"
fi

echo "[*] Generating pre-signed URL using region $AWS_REGION..."
SIGNED_URL=$(aws s3 presign s3://$S3_BUCKET/$S3_KEY --expires-in 300 --region "$AWS_REGION" --endpoint-url https://s3.dualstack.$AWS_REGION.amazonaws.com)
echo "[+] Presigned URL generated."
echo "$SIGNED_URL"

### Transfer command to bastion ###
echo "[*] Connecting to bastion to run wget for cloudflared .deb"
ssh -i ./build/${PROJECT_NAME}-bastion.pem bastion@${BASTION_IP} "wget -6 -O cloudflared.deb '$SIGNED_URL'"

ssh -i ./build/${PROJECT_NAME}-bastion.pem bastion@${BASTION_IP} 'bash -s' <<'EOF'
cat <<'SCRIPT' > ~/redirector_setup.sh
#!/bin/bash
set -euo pipefail

# your commands here
echo "Starting redirector setup..."

CF_API_TOKEN="PASTE_YOUR_API_TOKEN_HERE"
CF_ZONE_ID="PASTE_YOUR_ZONE_ID_HERE"
CF_ACCOUNT_ID="PASTE_YOUR_ACCOUNT_ID_HERE"
TUNNEL_NAME="my-c2-tunnel"
TUNNEL_DOMAIN="beacon.example.com"
LOCAL_USER="ubuntu"
CLOUDFLARED_DIR="/home/$LOCAL_USER/.cloudflared"

cloudflared tunnel create "$TUNNEL_NAME"
TUNNEL_ID=$(basename "$CLOUDFLARED_DIR"/*.json)
TUNNEL_ID="${TUNNEL_ID%.json}"
echo "Tunnel ID: $TUNNEL_ID"

mkdir -p "$CLOUDFLARED_DIR"

cat <<CONFIG > "$CLOUDFLARED_DIR/config.yml"
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
CONFIG

curl -s -X POST "https://api.cloudflare.com/client/v4/zones/\$CF_ZONE_ID/dns_records" \
  -H "Authorization: Bearer \$CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type":"CNAME",
    "name":"'"$TUNNEL_DOMAIN"'",
    "content":"'"$TUNNEL_ID"'.cfargotunnel.com",
    "ttl":120,
    "proxied":true
  }' | jq .

echo "Done. To run:"
echo "cloudflared --no-autoupdate --protocol http2 --edge-ip-version 6 tunnel run \\\"\$TUNNEL_NAME\\\""
SCRIPT

chmod +x ~/redirector_setup.sh
EOF


####  CONFIGURATION ###
#CF_API_TOKEN="PASTE_YOUR_API_TOKEN_HERE"
#CF_ZONE_ID="PASTE_YOUR_ZONE_ID_HERE"
#CF_ACCOUNT_ID="PASTE_YOUR_ACCOUNT_ID_HERE"
#TUNNEL_NAME="my-c2-tunnel"
#TUNNEL_DOMAIN="beacon.example.com"   # Your C2 hostname
#LOCAL_USER="ubuntu"
#
#CLOUDFLARED_DIR="/home/$LOCAL_USER/.cloudflared"
#
#echo "[*] Creating Cloudflare Tunnel: $TUNNEL_NAME"
#cloudflared tunnel create "$TUNNEL_NAME"
#
## Get the Tunnel ID (JSON filename)
#TUNNEL_ID=$(basename "$CLOUDFLARED_DIR"/*.json)
#TUNNEL_ID="${TUNNEL_ID%.json}"
#echo "[+] Tunnel ID: $TUNNEL_ID"
#
#echo "[*] Writing config.yml"
#cat <<EOF > "$CLOUDFLARED_DIR/config.yml"
#tunnel: $TUNNEL_ID
#credentials-file: $CLOUDFLARED_DIR/$TUNNEL_ID.json
#
#protocol: http2
#no-autoupdate: true
#edge-ip-version: 6
#
#ingress:
#  - hostname: $TUNNEL_DOMAIN
#    service: https://localhost:443
#    originRequest:
#      noTLSVerify: true
#  - service: http_status:404
#EOF
#
#echo "[*] Creating CNAME DNS record for $TUNNEL_DOMAIN → $TUNNEL_ID.cfargotunnel.com"
#curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
#  -H "Authorization: Bearer $CF_API_TOKEN" \
#  -H "Content-Type: application/json" \
#  --data '{
#    "type":"CNAME",
#    "name":"'"$TUNNEL_DOMAIN"'",
#    "content":"'"$TUNNEL_ID"'.cfargotunnel.com",
#    "ttl":120,
#    "proxied":true
#  }' | jq .
#
#echo "[✅] Setup complete."
#echo "[] To run the tunnel, execute:"
#echo
#echo "cloudflared --no-autoupdate --protocol http2 --edge-ip-version 6 tunnel run \"$TUNNEL_NAME\""
#
