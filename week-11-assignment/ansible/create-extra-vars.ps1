# PowerShell script to generate extra_vars.yml with proper formatting

# First, change to the terraform directory to access outputs
Set-Location -Path "../terraform"

# Get Terraform outputs
$s3_user_access_key = terraform output -raw s3_user_access_key
$s3_user_secret_key = terraform output -raw s3_user_secret_key
$media_bucket_name = terraform output -raw media_bucket_name
$media_bucket_url = terraform output -raw media_bucket_url
$frontend_bucket_name = terraform output -raw frontend_bucket_name
$frontend_bucket_website_endpoint = terraform output -raw frontend_bucket_website_endpoint
$ec2_public_ip = terraform output -raw ec2_public_ip

# Create content for extra_vars.yml with proper YAML formatting
$extraVarsContent = @"
---
# S3 configuration
s3_user_access_key: "$s3_user_access_key"
s3_user_secret_key: "$s3_user_secret_key"

# Bucket information
media_bucket_name: "$media_bucket_name"
media_bucket_url: "$media_bucket_url"
frontend_bucket_name: "$frontend_bucket_name"
frontend_bucket_website_endpoint: "$frontend_bucket_website_endpoint"

# EC2 information
ec2_public_ip: "$ec2_public_ip"
"@

# Change back to ansible directory
Set-Location -Path "../ansible"

# Write content to extra_vars.yml with UTF8 encoding without BOM
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines((Resolve-Path "extra_vars.yml"), $extraVarsContent, $utf8NoBomEncoding)

Write-Host "Successfully created extra_vars.yml with Terraform outputs." -ForegroundColor Green
Write-Host "You can now run the Ansible playbook with:" -ForegroundColor Green
Write-Host "ansible-playbook -i inventory/hosts deploy-playbook.yml --extra-vars `"@extra_vars.yml`"" -ForegroundColor Green 