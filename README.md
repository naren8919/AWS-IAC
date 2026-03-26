# AWS Infrastructure as Code - Terraform Project

## Project Overview
This Terraform project creates a complete AWS infrastructure with:
- VPC with public and private subnets
- NAT Gateway for private subnet internet access
- 2 EC2 instances (one public, one private) with Tomcat
- Application Load Balancer (ALB)
- S3 bucket for storing EC2 logs
- IAM users and groups with proper permissions
- CloudWatch alarms for CPU monitoring
- Security groups for network access control

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│              AWS Region (us-east-2)             │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                       │  │
│  │                                          │  │
│  │  ┌────────────────────────────────────┐ │  │
│  │  │ Public Subnet (10.0.1.0/24)        │ │  │
│  │  │ - Public EC2 Instance (Tomcat)    │ │  │
│  │  │ - NAT Gateway                     │ │  │
│  │  │ - ALB                             │ │  │
│  │  └────────────────────────────────────┘ │  │
│  │                                          │  │
│  │  ┌────────────────────────────────────┐ │  │
│  │  │ Private Subnet (10.0.2.0/24)       │ │  │
│  │  │ - Private EC2 Instance (Tomcat)   │ │  │
│  │  │ - Internet via NAT Gateway        │ │  │
│  │  └────────────────────────────────────┘ │  │
│  │                                          │  │
│  │  IGW (Internet Gateway)                 │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  S3 Bucket (ec2-logs-xxxxx) - Log Storage      │
└─────────────────────────────────────────────────┘

IAM Users:
- Naren (Admin Access)
- Narain (Read-Only EC2, Read S3, Read CloudWatch)
```

## File Structure

```
├── provider.tf              # AWS provider configuration
├── variable.tf              # Input variables with defaults
├── vpc.tf                   # VPC, Subnets, IGW, NAT, Route Tables
├── sg.tf                    # Security Groups for ALB and EC2
├── ec2-iam-role.tf         # IAM role/policy/instance profile for EC2
├── ec2.tf                   # EC2 instances configuration
├── alb.tf                   # Application Load Balancer, Target Groups
├── cloudwatch.tf            # CloudWatch Alarms
├── iam.tf                   # IAM Users and Groups
├── S3.tf                    # S3 bucket for logs
├── backend.tf               # Remote state configuration
├── output.tf                # Output values
├── user-data.sh             # EC2 user data script
└── terraform.tfvars         # Variables file (not included - create locally)
```

## Prerequisites

### 1. AWS Account Setup (Free Tier)
For AWS Free Tier without access/secret keys:

**Option A: Use AWS CloudShell (Recommended for Learning)**
```bash
# Go to AWS Console → CloudShell (available in most regions)
# CloudShell provides temporary credentials automatically
```

**Option B: Create Programmatic Access**
1. Log in to AWS Management Console
2. Go to IAM → Users → Create User
3. Enable "Programmatic access"
4. Attach policy: "AdministratorAccess" (for testing only)
5. Copy Access Key ID and Secret Access Key
6. Configure AWS CLI:
   ```bash
   aws configure
   # Enter Access Key ID
   # Enter Secret Access Key
   # Enter Region: us-east-2
   # Enter Output format: json
   ```

### 2. Prerequisites on Local Machine

#### Windows Setup:
```powershell
# Install Terraform
# Download from: https://www.terraform.io/downloads.html
# Add to PATH or use Windows Subsystem for Linux (WSL2)

# Using Chocolatey (if installed)
choco install terraform

# Verify installation
terraform --version

# Install AWS CLI
choco install awscliv2

# Configure AWS credentials
aws configure
```

#### macOS Setup:
```bash
# Using Homebrew
brew install terraform
brew install awscli

# Verify installation
terraform --version
aws --version

# Configure AWS credentials
aws configure
```

#### Linux Setup:
```bash
# Download and install Terraform
wget https://releases.hashicorp.com/terraform/1.x.x/terraform_1.x.x_linux_amd64.zip
unzip terraform_1.x.x_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install AWS CLI
pip install awscli

# Verify installation
terraform --version
aws --version

# Configure AWS credentials
aws configure
```

### 3. Create EC2 Key Pair

```bash
# Using AWS CLI
aws ec2 create-key-pair --key-name terraform-key --region us-east-2 --query 'KeyMaterial' --output text > terraform-key.pem

# Linux/macOS: Set permissions
chmod 400 terraform-key.pem

# Windows: Use PuTTY or WSL for SSH
```

**Note:** If you leave `key_name` blank in `terraform.tfvars`, Terraform will generate an SSH keypair
and create an AWS key pair for you. The private key will be written to a file named
`<project>_generated_key.pem` (for example `AWS-IAC_generated_key.pem`) in the workspace. Use that
PEM file when SSH'ing if Terraform generated the key.

## Deployment Steps

### Step 1: Initialize Terraform
```bash
cd /path/to/AWS-IAC
terraform init
```

**Output:**
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully configured!
```

### Step 2: Validate Configuration
```bash
terraform validate
```

**Expected Output:**
```
Success! The configuration is valid.
```

### Step 3: Format Code (Best Practice)
```bash
terraform fmt -recursive
```

### Step 4: Plan Deployment (Preview Changes)
```bash
terraform plan -out=tfplan
```

This shows all resources that will be created. Review carefully!

### Step 5: Apply Configuration
```bash
terraform apply tfplan
```

**Will create:**
- 1 VPC
- 2 Subnets (Public + Private)
- 1 Internet Gateway
- 1 NAT Gateway (with Elastic IP)
- 2 Route Tables
- 2 EC2 Instances
- 1 ALB with Target Groups
- 1 S3 Bucket
- 2 CloudWatch Alarms
- 2 IAM Users
- 2 IAM Groups

### Step 6: Verify Deployment
```bash
# View outputs
terraform output

# Check resources in AWS Console
# EC2 → Instances (should see 2 instances)
# VPC → VPCs (should see new VPC)
# S3 → Buckets (should see new S3 bucket)
```

## Configuration Details

### Variables (`variable.tf`)
```hcl
region        = "us-east-2"           # AWS region
instance_type = "t2.micro"            # Free tier eligible
project       = "AWS-IAC"             # Project name tag
# AMI: leave blank to auto-select the latest Amazon Linux 2 AMI for the region
AMI           = ""                     # If empty, configuration uses data.aws_ami to lookup latest Amazon Linux 2
key_name      = "terraform-key"       # EC2 Key Pair name
```

### VPC Network
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 2 subnets (multi-AZ) with IGW
- **Private Subnets**: 2 subnets (multi-AZ) with NAT Gateway

### EC2 Instances
- **AMI**: Amazon Linux 2 (Free Tier)
- **Instance Type**: t2.micro (Free Tier)
- **Root Volume**: 8GB gp2 (Free Tier)

**User Data Script** (`user-data.sh`):
- Installs and starts Tomcat
- Deploys a simple index.html
- Pushes logs to S3 bucket

### IAM Structure

**Groups:**
1. **AdminGroup** → Full AWS access
2. **ReadOnly-ec2-Group** → EC2 read-only + S3/CloudWatch read access

**Users:**
1. **Naren** → Member of AdminGroup
2. **Narain** → Member of ReadOnly-ec2-Group

### Security Groups

**ALB Security Group:**
- Inbound: HTTP (80), HTTPS (443)
- Outbound: All traffic

**EC2 Security Group:**
- Inbound: HTTP (80), HTTPS (443), SSH (22), Tomcat (8080) from ALB
- Outbound: All traffic

## Monitoring and Logging

### CloudWatch Alarms
- **CPU > 80%** triggers alarm for both instances
- Edit threshold in `cloudwatch.tf` if needed

### Log Storage
- EC2 instances push logs to S3 bucket
- Bucket name: `ec2-logs-{randomid}`
- Logs stored with hostname: `{hostname}-messages.log`

## Cost Estimation (Free Tier)

| Resource | Monthly Cost | Notes |
|----------|--------------|-------|
| 2x t2.micro EC2 | Free | 750 hours free/month |
| NAT Gateway | $0.045/GB | Data transfer cost |
| ALB | $16.20 | NOT FREE - delete if not needed |
| S3 Storage | Free | First 5GB free |
| CloudWatch | Free | Free tier includes alarms |
| **Total Estimated** | **~$16-25** | ALB is paid; remove to stay free |

**To stay within free tier, delete the ALB:**
```bash
# Remove alb.tf resource blocks if ALB charges concern you
# Or modify to access instances directly via public IP
```

## Cleanup (Destroy Infrastructure)

```bash
# Preview what will be deleted
terraform plan -destroy

# Delete all resources
terraform destroy

# Confirm by typing 'yes' when prompted
```

**Warning:** This permanently deletes all resources!

## Real-Time Company Standards

### 1. State Management
```hcl
# backend.tf - Remote state to prevent loss
terraform {
  backend "s3" {
    bucket = "terraform-remote-state-company"
    key    = "prod/terraform.tfstate"
    region = "us-east-2"
    encrypt = true
  }
}
```

### 2. Workspace Strategy
```bash
# Use workspaces for dev/staging/prod
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch between workspaces
terraform workspace select prod
```

### 3. Variables Organization
```
terraform/
├── dev/
│   └── terraform.tfvars
├── staging/
│   └── terraform.tfvars
└── prod/
    └── terraform.tfvars
```

### 4. Tagging Strategy
```hcl
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner_email
  }
}

resource "aws_instance" "example" {
  tags = merge(local.common_tags, {
    Name = "App-Server"
  })
}
```

### 5. Code Review Checklist
Before applying in production:
- ✅ Validate syntax: `terraform validate`
- ✅ Format code: `terraform fmt -recursive`
- ✅ Check plan: `terraform plan -out=tfplan`
- ✅ Review security groups (not too permissive)
- ✅ Enable encryption for databases/S3
- ✅ Use variables for sensitive data
- ✅ Document any manual changes (Git)

### 6. Pipeline Example (GitHub Actions)

```yaml
name: Terraform CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
      with:
        terraform_version: 1.5.0
    
    - name: Terraform Init
      run: terraform init
    
    - name: Terraform Validate
      run: terraform validate
    
    - name: Terraform Plan
      run: terraform plan -out=tfplan
    
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply tfplan
```

## Troubleshooting

### Issue: "user_data.sh" not found
**Solution:**
```bash
# Make sure user-data.sh exists in same directory as .tf files
ls -la user-data.sh  # Linux/macOS
dir user-data.sh     # Windows
```

### Issue: S3 bucket name already exists
**Solution:**
```hcl
# S3 names must be globally unique
# random_id in S3.tf should prevent this, but if it happens:

resource "aws_s3_bucket" "logs" {
  bucket = "ec2-logs-${var.project}-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}
```

### Issue: KeyName does not exist
**Solution:**
```bash
# Create key pair in AWS CLI
aws ec2 create-key-pair --key-name terraform-key --region us-east-2

# Or create manually in AWS Console:
# EC2 → Key Pairs → Create → Save .pem file
```

### Issue: IAM user creation fails
**Solution:**
Make sure your AWS account has permissions to create IAM users. Free tier accounts can do this.

### Issue: "Error: error reading S3 bucket"
**Solution:**
```bash
# This can happen due to S3 eventual consistency
# Wait a few seconds and try again:
terraform plan
```

## Security Best Practices

### DO NOT in Production:
- ❌ Commit `.tfvars` with secrets to Git
- ❌ Use "0.0.0.0/0" for SSH in security groups
- ❌ Store state file locally
- ❌ Use admin policies for all users
- ❌ Hardcode credentials

### DO in Production:
- ✅ Use remote S3 backend with encryption
- ✅ Enable MFA on AWS Console
- ✅ Use specific IAM policies (least privilege)
- ✅ Enable VPC Flow Logs
- ✅ Use AWS Secrets Manager for sensitive data
- ✅ Enable CloudTrail for audit
- ✅ Use terraform-compliance for security checks

## Next Steps for Learning

1. **Modify the infrastructure:**
   - Add RDS database
   - Add Auto Scaling Group
   - Add Lambda functions

2. **Advanced Topics:**
   - Terraform modules for code reuse
   - Separate network layer using modules
   - State locking with DynamoDB

3. **Best Practices:**
   - Implement terraform-docs for documentation
   - Use pre-commit hooks for validation
   - Set up CI/CD pipeline

## Additional Resources

- **Terraform Docs**: https://www.terraform.io/docs
- **AWS Provider Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Free Tier Eligibility**: https://aws.amazon.com/free/
- **Terraform Best Practices**: https://www.terraform.io/docs/cloud/guides/recommended-practices

## Support and Troubleshooting

For detailed logs during deployment:
```bash
export TF_LOG=DEBUG
terraform apply

# To disable logging
unset TF_LOG
```

Monitor AWS Console during deployment:
- EC2 → Instances (watch status)
- CloudFormation → Stacks (see creation progress)
- Logs → CloudWatch (monitor any errors)

---

**Last Updated**: December 2025  
**Terraform Version**: 1.5+  
**AWS Provider Version**: 5.0+
