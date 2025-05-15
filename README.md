# week11
week 11 assignment 
Rahaf Alrajeh 
SDA1013

Step 1: Terraform - Provision Infrastructure

```bash
cd solution/terraform
terraform init
terraform plan
terraform apply

After Apply – Get Output
i writ 
terraform output
terraform output -raw ec2_public_ip
terraform output -raw s3_user_access_key
terraform output -raw s3_user_secret_key


Step 2: Ansible - Backend Provisioning
i updated my inventory
[backend]
backend_server ansible_host=ec2-user ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/rahafkey.pem


i write 
mkdir -p ~/.ssh
cp /mnt/c/Users/ec2-user/.ssh/rahafkey.pem ~/.ssh/

chmod 600 ~/.ssh/rahafkey.pem


Step 3: Ansible Variables

cd solution/ansible
chmod +x create-extra-vars.sh
./create-extra-vars.sh

Step 4: Run Ansible Playbook
i write 
cd solution/ansible
ansible-playbook -i inventory/hosts deploy-playbook.yml --extra-vars "@extra_vars.yml"


i check the url from the AWS bucket and it's work and i uplodded post.
there is also screenshot.
