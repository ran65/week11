#!/bin/bash

# Setup script for configuring SSH access for Ansible playbook
# This script helps configure the inventory file with the correct SSH key path

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}SSH Setup Helper for Ansible Playbooks${NC}"
echo -e "${GREEN}======================================${NC}"
echo

# Get terraform outputs if available
if [ -d "../terraform" ]; then
  echo -e "${YELLOW}Trying to get EC2 IP from Terraform outputs...${NC}"
  cd ../terraform
  EC2_IP=$(terraform output -raw ec2_public_ip 2>/dev/null)
  cd ../ansible
  
  if [ ! -z "$EC2_IP" ]; then
    echo -e "${GREEN}Found EC2 IP: ${EC2_IP}${NC}"
  else
    echo -e "${YELLOW}Could not get EC2 IP from Terraform. You'll need to enter it manually.${NC}"
  fi
fi

# Ask for EC2 IP if not found
if [ -z "$EC2_IP" ]; then
  read -p "Enter your EC2 instance's public IP: " EC2_IP
fi

# Ask for SSH key path
echo
echo -e "${YELLOW}Now, we need the path to your SSH private key.${NC}"
echo -e "Examples:"
echo -e "  - Windows WSL: /mnt/c/Users/username/.ssh/key.pem"
echo -e "  - Linux: /home/username/.ssh/key.pem"
read -p "Enter the absolute path to your SSH private key: " SSH_KEY_PATH

# Verify the key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo -e "${RED}Error: The SSH key file does not exist at: $SSH_KEY_PATH${NC}"
  echo -e "Please check the path and try again."
  exit 1
fi

# If path is in Windows location (/mnt/c/...), offer to copy to local WSL ~/.ssh
if [[ "$SSH_KEY_PATH" == "/mnt/"* ]]; then
  echo -e "${YELLOW}Detected Windows path. Would you like to copy the key to your WSL ~/.ssh directory?${NC}"
  echo -e "This can help prevent permission issues when using Ansible."
  read -p "Copy key to WSL ~/.ssh? (y/n): " COPY_KEY
  
  if [[ "$COPY_KEY" == "y" || "$COPY_KEY" == "Y" ]]; then
    # Create ~/.ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    
    # Get the filename from the path
    KEY_FILENAME=$(basename "$SSH_KEY_PATH")
    
    # Copy the key
    cp "$SSH_KEY_PATH" ~/.ssh/
    
    # Update the path to the copied key
    SSH_KEY_PATH=~/.ssh/$KEY_FILENAME
    
    echo -e "${GREEN}Copied key to $SSH_KEY_PATH${NC}"
  fi
fi

# Set proper permissions on the key
chmod 600 "$SSH_KEY_PATH"
echo -e "${GREEN}Set permissions on SSH key to 600.${NC}"

# Update the inventory file
echo
echo -e "${YELLOW}Updating inventory file...${NC}"
cat > inventory/hosts << EOF
[backend]
backend_server ansible_host=${EC2_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

echo -e "${GREEN}Updated inventory file with EC2 IP: ${EC2_IP} and SSH key: ${SSH_KEY_PATH}${NC}"

# Test SSH connection
echo
echo -e "${YELLOW}Testing SSH connection...${NC}"
echo -e "Running: ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@${EC2_IP} 'echo SSH connection successful'"
SSH_TEST=$(ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@${EC2_IP} 'echo SSH connection successful' 2>&1)

if [[ $SSH_TEST == *"SSH connection successful"* ]]; then
  echo -e "${GREEN}SSH connection test successful!${NC}"
  echo -e "\nYou can now run the Ansible playbook with:"
  echo -e "${GREEN}ansible-playbook -i inventory/hosts deploy-playbook.yml --extra-vars \"@extra_vars.yml\"${NC}"
else
  echo -e "${RED}SSH connection test failed.${NC}"
  echo -e "Error: $SSH_TEST"
  echo -e "\nPossible solutions:"
  echo -e "1. Verify your EC2 instance is running"
  echo -e "2. Check that the security group allows SSH (port 22)"
  echo -e "3. Verify the key pair used to launch the EC2 instance matches your private key"
  echo -e "4. Try connecting manually: ssh -i ${SSH_KEY_PATH} ubuntu@${EC2_IP}"
fi 