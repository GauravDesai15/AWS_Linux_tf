# Terraform AWS EC2 Infrastructure Lab

A hands-on Infrastructure as Code (IaC) project demonstrating the provisioning, configuration, validation, lifecycle management, and cleanup of AWS infrastructure using **Terraform**.

This project deploys an Amazon Linux 2023 EC2 instance running Nginx inside a custom AWS VPC. It uses AWS Systems Manager Session Manager for remote administration without requiring inbound SSH access.

The lab also demonstrates Terraform state management, infrastructure updates, configuration drift detection, and desired-state reconciliation.

## 1. Architecture Overview

The infrastructure consists of:

- **AWS Region:** `eu-west-2` (London)
- **VPC:** Custom VPC with CIDR `10.0.0.0/16`
- **Public Subnet:** `10.0.1.0/24`
- **Internet Gateway:** Provides internet connectivity
- **Route Table:** Routes `0.0.0.0/0` through the internet gateway
- **Security Group:** Allows inbound HTTP on TCP port 80 and outbound IPv4 traffic
- **EC2 Instance:** Amazon Linux 2023, `t3.micro`
- **Storage:** Encrypted 20 GiB gp3 EBS root volume
- **IAM Role:** EC2 role with `AmazonSSMManagedInstanceCore`
- **AWS Systems Manager:** Remote access without an SSH key pair
- **Nginx:** Installed and configured automatically through EC2 user data

### Network Architecture

```text
                   Internet
                      |
                      |
               Internet Gateway
                      |
                      |
             AWS VPC (10.0.0.0/16)
                      |
             Public Route Table
                      |
          Public Subnet (10.0.1.0/24)
                      |
               Security Group
               HTTP: TCP 80
                      |
              Amazon Linux EC2
                 (t3.micro)
                      |
                 Nginx Server
                      |
               HTTP Web Page
```

Administrative access is provided separately through AWS Systems Manager Session Manager.

## 2. Technologies Used

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure provisioning and lifecycle management |
| AWS EC2 | Virtual machine hosting |
| AWS VPC | Network isolation and routing |
| AWS IAM | Instance permissions and access control |
| AWS Systems Manager | Remote instance administration |
| Amazon Linux 2023 | Linux operating system |
| Nginx | HTTP web server |
| Bash | EC2 bootstrap automation |
| AWS CLI | AWS authentication and management |
| PowerShell | Local Terraform execution |

## 3. Prerequisites

Before deploying this infrastructure, ensure you have:

- Terraform version 1.6 or later
- AWS CLI installed and configured
- An AWS IAM identity with the required EC2, VPC and IAM permissions
- Access to the AWS Management Console
- An AWS account with appropriate service quotas
- AWS billing alerts configured

### Verify Terraform

```powershell
terraform version
```

### Verify AWS CLI

```powershell
aws --version
```

### Verify AWS Authentication

This lab was configured to use an AWS CLI named profile called `terraform-lab`.

```powershell
aws sts get-caller-identity --profile terraform-lab
```

The Terraform AWS provider uses:

```hcl
provider "aws" {
  region  = var.aws_region
  profile = "terraform-lab"

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Environment = "lab"
    }
  }
}
```

For other environments, change the AWS profile and region as required. Avoid hardcoding access keys in Terraform configuration.

## 4. Project Structure

```text
ec2-basics/
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── user_data.sh
├── terraform.tfvars.example
├── .gitignore
└── README.md
```

The Terraform configuration defines the networking, security group, IAM role, instance profile, EC2 instance and associated infrastructure.

The `user_data.sh` script automatically installs and starts Nginx during instance initialization.

## 5. Infrastructure Deployment

### Step 1 — Clone the repository

```powershell
git clone <your-repository-url>
cd ec2-basics
```

Replace the placeholder with your actual GitHub repository URL.

### Step 2 — Configure variables

Copy the example variables file if provided:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Example configuration:

```hcl
aws_region    = "eu-west-2"
project_name  = "ec2-basics-lab"
instance_type = "t3.micro"
enable_http   = true
key_name      = null
ssh_cidr      = null
```

The default configuration uses Session Manager rather than SSH.

### Step 3 — Initialize Terraform

```powershell
terraform init
```

Downloads and initializes the required Terraform providers.

### Step 4 — Format and validate

```powershell
terraform fmt
terraform validate
```

### Step 5 — Generate the execution plan

```powershell
terraform plan -out=lab.tfplan
```

The initial deployment plan creates 12 AWS resources.

### Step 6 — Deploy infrastructure

```powershell
terraform apply lab.tfplan
```

Terraform provisions the AWS infrastructure according to the saved execution plan.

### Step 7 — View outputs

```powershell
terraform output
```

The configuration exposes:

- `instance_id`
- `public_ip`
- `website_url`
- `ssm_start_session`

## 6. Nginx Web Server Automation

The EC2 instance uses a Bash bootstrap script (`user_data.sh`) to install and configure Nginx.

```bash
#!/bin/bash
set -euxo pipefail

dnf install -y nginx
systemctl enable --now nginx

cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Terraform EC2 Lab</title>
</head>
<body>
  <h1>Terraform EC2 Lab is running!</h1>
  <p>Amazon Linux 2023 + Nginx</p>
</body>
</html>
HTML
```

The script runs automatically when the EC2 instance first launches.

### Verify the web application

```powershell
terraform output -raw website_url
```

Open the returned HTTP URL in a browser.

Expected page:

```text
Terraform EC2 Lab is running!
Amazon Linux 2023 + Nginx
```

The webpage was successfully verified from an external browser during the lab.

## 7. Connect Using AWS Systems Manager

The EC2 instance is assigned an IAM instance profile with the AWS-managed policy:

```text
AmazonSSMManagedInstanceCore
```

This enables Systems Manager connectivity without opening inbound SSH port 22.

### Console connection

1. Open the AWS EC2 Console.
2. Select the running instance.
3. Choose Connect.
4. Select Session Manager.
5. Click Connect.

### Verify Linux and Nginx

```bash
whoami
cat /etc/os-release
sudo systemctl status nginx
curl -I http://localhost
```

The lab successfully verified:

```text
User: ssm-user
OS: Amazon Linux 2023
Nginx: active (running)
HTTP/1.1 200 OK
```

For CLI-based Session Manager access, install the Session Manager plugin and ensure the selected AWS identity has the necessary session permissions.

## 8. Terraform State Management

Terraform maintains state to track infrastructure resources and their attributes.

### List resources

```powershell
terraform state list
```

The deployed lab contained 12 managed resources and two data sources.

### Inspect the EC2 instance

```powershell
terraform state show aws_instance.web
```

This displays information such as the instance type, networking, storage, security group and tags.

### Verify desired state

```powershell
terraform plan
```

When the actual infrastructure matches the configuration:

```text
No changes. Your infrastructure matches the configuration.
```

## 9. Infrastructure Modification

The lab demonstrated modifying an existing EC2 instance without replacing it.

Additional tags were added to the `aws_instance.web` resource:

```hcl
tags = {
  Name     = "${var.project_name}-web"
  Training = "DevOps-SRE"
  owner    = "TerraformLab"
}
```

After running:

```powershell
terraform fmt
terraform validate
terraform plan
```

Terraform identified an in-place modification:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

The changes were applied successfully without recreating the EC2 instance.

## 10. Terraform Configuration Drift Detection

A practical drift-detection exercise was performed by manually modifying an EC2 tag through the AWS Console.

### Manual change

The `Training` tag was changed from:

```text
DevOps-SRE
```

to:

```text
DevOps-SRE-Train
```

### Detect drift

```powershell
terraform plan
```

Terraform detected the difference and proposed restoring the configured value:

```diff
~ "Training" = "DevOps-SRE-Train" -> "DevOps-SRE"
```

Execution plan:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

### Restore the desired configuration

```powershell
terraform apply
```

After approval, Terraform updated the tag in place.

A subsequent `terraform plan` can be used to verify that the infrastructure matches the configuration again.

**Key learning:** Terraform detects configuration drift during planning, but changes are not automatically corrected until an apply operation is executed.

## 11. Optional SSH Access

The configuration supports optional SSH access.

To enable it:

1. Create an EC2 key pair in the deployment region.
2. Configure `key_name` with the existing key pair name.
3. Set `ssh_cidr` to your public IPv4 address using `/32` notation.
4. Review the Terraform plan before applying changes.

Example:

```hcl
key_name = "my-existing-key"
ssh_cidr = "203.0.113.10/32"
```

Never expose SSH to `0.0.0.0/0` in this lab.

For the completed exercise, SSH was disabled and Systems Manager was used instead.

## 12. Infrastructure Cleanup

To preview which resources will be removed:

```powershell
terraform plan -destroy
```

To destroy the infrastructure:

```powershell
terraform destroy
```

Review the destruction plan and confirm when prompted.

The lab's resources were successfully destroyed after completing the hands-on exercises.

Destroying the EC2 instance also deletes its configured root EBS volume. The Terraform configuration files remain available locally for future deployments.

## 13. Security Considerations

Security measures included in this lab:

- EC2 access through AWS Systems Manager instead of public SSH
- IAM instance role rather than embedded AWS credentials
- IMDSv2 required for EC2 instance metadata access
- Encrypted EBS root volume
- SSH restricted to an optional single IPv4 address
- AWS resource tagging for identification and management
- Terraform-managed networking and security configuration

### Production improvements

This is a training environment, not a production-ready architecture.

For production workloads, consider:

- Private subnets for application instances
- Application Load Balancer with HTTPS/TLS
- Restricted outbound security group rules
- Least-privilege IAM policies
- Temporary AWS credentials and role-based authentication
- Secure remote Terraform state with locking
- Monitoring, alerting and centralised logging
- High availability across multiple Availability Zones

## 14. Cost Management

AWS resources may incur charges, including:

- EC2 compute
- EBS storage
- Public IPv4 addresses
- Other chargeable services used by the deployment

AWS Free Tier eligibility depends on account-specific conditions.

Configure billing budgets and alerts before deployment, and destroy lab resources when they are no longer needed.

AWS budget alerts do not automatically stop resources or prevent charges.

## 15. GitHub Repository Security

Do not commit Terraform state, credentials, private keys, saved execution plans or local variable files containing secrets.

Recommended `.gitignore`:

```gitignore
# Terraform working directory
**/.terraform/*

# Terraform state
*.tfstate
*.tfstate.*

# Terraform plans
*.tfplan
tfplan
tfplan.*
*.tfplan.*
*.plan

# Sensitive variable files
*.tfvars
*.tfvars.json
!*.tfvars.example

# Terraform crash logs
crash.log
crash.*.log

# Local overrides
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Credentials and private keys
*.pem
*.key
.env
.env.*
```

Commit `.terraform.lock.hcl` to version control so provider versions remain reproducible across environments.

## 16. Key Learning Outcomes

Through this project, I gained hands-on experience in:

- Provisioning AWS infrastructure using Terraform
- Designing custom VPC networking and routing
- Configuring EC2 security groups
- Implementing IAM instance profiles for Systems Manager
- Automating Linux server configuration using user data
- Deploying and verifying an Nginx web server
- Inspecting and managing Terraform state
- Performing safe in-place infrastructure updates
- Detecting and correcting infrastructure configuration drift
- Understanding Terraform resource lifecycle operations
- Safely destroying cloud resources after testing

## 17. Future Enhancements

Planned improvements include:

- Refactoring Terraform configuration into reusable modules
- Configuring remote state storage and locking
- Adding a Windows Server EC2 deployment
- Implementing automated Terraform validation with GitHub Actions
- Introducing monitoring and alerting
- Exploring multi-environment infrastructure provisioning

---

**Project Status:** Completed — Infrastructure deployed, verified, modified, drift-tested and destroyed successfully.

**Purpose:** Hands-on DevOps, AWS cloud engineering, Infrastructure as Code and Site Reliability Engineering practice.
