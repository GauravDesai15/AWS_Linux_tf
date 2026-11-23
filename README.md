# Terraform EC2 Basics Lab

Provisions a dedicated VPC, public subnet, internet gateway, public route table, security group, IAM role + instance profile for AWS Systems Manager, and Amazon Linux 2023 EC2 instance with an encrypted 20 GiB gp3 root volume and Nginx.

## Requirements
- Terraform >= 1.6
- AWS CLI configured with an IAM identity authorized to create VPC, EC2, IAM and SSM-related resources
- AWS account with appropriate quotas and billing alerts

## Deploy
```bash
aws sts get-caller-identity
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan -out=lab.tfplan
terraform apply lab.tfplan
terraform output
```

On Windows PowerShell, replace `cp` with `Copy-Item`.

Browse to `terraform output -raw website_url` after cloud-init finishes (may take a couple minutes). Session Manager connection requires the Session Manager plugin installed for AWS CLI, and SSM agent connectivity/registration. Use the AWS console's Session Manager if preferred.

## Optional SSH
Create an EC2 key pair in the same region, keep the private key safe, and set `key_name` and `ssh_cidr` (your public IPv4 address with `/32`) in `terraform.tfvars`. Never use `0.0.0.0/0` for SSH.

## Destroy
```bash
terraform destroy
```

## Security and costs
- The demo exposes port 80 publicly; it is HTTP, not HTTPS. Disable with `enable_http = false` when not needed.
- EC2 public IPv4, compute and EBS may incur charges. Check AWS pricing and free-tier eligibility for your account.
- Terraform state is stored locally and must be protected; never commit it to git. Use a secured remote backend for team/production work.
- For production, use private subnets, SSM/VPC endpoints or NAT as appropriate, an ALB with TLS, tighter outbound rules, and a remote backend.
