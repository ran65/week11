#!/bin/bash

# Bash script to generate extra_vars.yml with proper formatting

# Colors for better readability
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Change to the terraform directory to access outputs
cd ../terraform

# Get Terraform outputs
S3_USER_ACCESS_KEY=$(terraform output -raw s3_user_access_key)
S3_USER_SECRET_KEY=$(terraform output -raw s3_user_secret_key)
MEDIA_BUCKET_NAME=$(terraform output -raw media_bucket_name)
MEDIA_BUCKET_URL=$(terraform output -raw media_bucket_url)
FRONTEND_BUCKET_NAME=$(terraform output -raw frontend_bucket_name)
FRONTEND_BUCKET_WEBSITE_ENDPOINT=$(terraform output -raw frontend_bucket_website_endpoint)
EC2_PUBLIC_IP=$(terraform output -raw ec2_public_ip)

# Change back to ansible directory
cd ../ansible

# Create extra_vars.yml file with proper YAML format
cat > extra_vars.yml << EOF
---
# S3 configuration
s3_user_access_key: "${S3_USER_ACCESS_KEY}"
s3_user_secret_key: "${S3_USER_SECRET_KEY}"

# Bucket information
media_bucket_name: "${MEDIA_BUCKET_NAME}"
media_bucket_url: "${MEDIA_BUCKET_URL}"
frontend_bucket_name: "${FRONTEND_BUCKET_NAME}"
frontend_bucket_website_endpoint: "${FRONTEND_BUCKET_WEBSITE_ENDPOINT}"

# EC2 information
ec2_public_ip: "${EC2_PUBLIC_IP}"
EOF

echo -e "${GREEN}Successfully created extra_vars.yml with Terraform outputs.${NC}"
echo -e "${GREEN}You can now run the Ansible playbook with:${NC}"
echo -e "${GREEN}ansible-playbook -i inventory/hosts deploy-playbook.yml --extra-vars \"@extra_vars.yml\"${NC}" 