# PowerShell Setup script for configuring SSH access for Ansible playbook
# This script helps configure the inventory file with the correct SSH key path

Write-Host "======================================" -ForegroundColor Green
Write-Host "SSH Setup Helper for Ansible Playbooks" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Get terraform outputs if available
if (Test-Path "../terraform") {
    Write-Host "Trying to get EC2 IP from Terraform outputs..." -ForegroundColor Yellow
    Set-Location -Path "../terraform"
    try {
        $EC2_IP = terraform output -raw ec2_public_ip 2>$null
        Set-Location -Path "../ansible"
        
        if (-not [string]::IsNullOrEmpty($EC2_IP)) {
            Write-Host "Found EC2 IP: $EC2_IP" -ForegroundColor Green
        } else {
            Write-Host "Could not get EC2 IP from Terraform. You'll need to enter it manually." -ForegroundColor Yellow
        }
    } catch {
        Set-Location -Path "../ansible"
        Write-Host "Error running Terraform output. You'll need to enter the EC2 IP manually." -ForegroundColor Yellow
    }
} else {
    Write-Host "Terraform directory not found. You'll need to enter the EC2 IP manually." -ForegroundColor Yellow
}

# Ask for EC2 IP if not found
if ([string]::IsNullOrEmpty($EC2_IP)) {
    $EC2_IP = Read-Host "Enter your EC2 instance's public IP"
}

# Ask for SSH key path
Write-Host ""
Write-Host "Now, we need the path to your SSH private key." -ForegroundColor Yellow
Write-Host "Examples:"
Write-Host "  - Windows: C:\Users\username\.ssh\key.pem"
Write-Host "  - Use forward slashes for Ansible: C:/Users/username/.ssh/key.pem"
$SSH_KEY_PATH = Read-Host "Enter the absolute path to your SSH private key"

# Convert backslashes to forward slashes for Ansible compatibility
$SSH_KEY_PATH = $SSH_KEY_PATH -replace "\\", "/"

# Verify the key exists
if (-not (Test-Path $SSH_KEY_PATH)) {
    Write-Host "Error: The SSH key file does not exist at: $SSH_KEY_PATH" -ForegroundColor Red
    Write-Host "Please check the path and try again."
    exit 1
}

# Update the inventory file
Write-Host ""
Write-Host "Updating inventory file..." -ForegroundColor Yellow

$inventoryContent = @"
[backend]
backend_server ansible_host=$EC2_IP ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY_PATH

[all:vars]
ansible_python_interpreter=/usr/bin/python3
"@

$inventoryContent | Out-File -FilePath "inventory/hosts" -Encoding ASCII

Write-Host "Updated inventory file with EC2 IP: $EC2_IP and SSH key: $SSH_KEY_PATH" -ForegroundColor Green

# Test SSH connection if OpenSSH is available
Write-Host ""
Write-Host "Testing SSH connection..." -ForegroundColor Yellow
Write-Host "Running: ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$EC2_IP 'echo SSH connection successful'"

try {
    # Check if ssh command is available
    if (Get-Command ssh -ErrorAction SilentlyContinue) {
        $sshResult = ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$EC2_IP "echo SSH connection successful" 2>&1
        
        if ($sshResult -like "*SSH connection successful*") {
            Write-Host "SSH connection test successful!" -ForegroundColor Green
            Write-Host "`nYou can now run the Ansible playbook with:" -ForegroundColor Green
            Write-Host "ansible-playbook -i inventory/hosts deploy-playbook.yml --extra-vars `"@extra_vars.yml`"" -ForegroundColor Green
        } else {
            Write-Host "SSH connection test failed." -ForegroundColor Red
            Write-Host "Error: $sshResult"
            Write-Host "`nPossible solutions:" -ForegroundColor Yellow
            Write-Host "1. Verify your EC2 instance is running"
            Write-Host "2. Check that the security group allows SSH (port 22)"
            Write-Host "3. Verify the key pair used to launch the EC2 instance matches your private key"
            Write-Host "4. Try connecting manually: ssh -i $SSH_KEY_PATH ubuntu@$EC2_IP"
        }
    } else {
        Write-Host "SSH command not found. Please verify SSH connectivity manually:" -ForegroundColor Yellow
        Write-Host "1. OpenSSH might not be installed or in your PATH"
        Write-Host "2. Try connecting manually to verify: ssh -i $SSH_KEY_PATH ubuntu@$EC2_IP"
    }
} catch {
    Write-Host "Error testing SSH connection: $_" -ForegroundColor Red
    Write-Host "Please verify SSH connectivity manually." -ForegroundColor Yellow
} 