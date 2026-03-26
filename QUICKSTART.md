# Quick Start Guide - AWS Infrastructure Deployment

## For Absolute Beginners

This guide walks you through deploying your Terraform infrastructure step-by-step.

---

## Step 1: Create AWS Free Tier Account (5 minutes)

### What is AWS Free Tier?
AWS gives you free usage of many services for 12 months:
- **2x t2.micro EC2 instances** (750 hours/month = always free)
- **5GB S3 storage** (free)
- **CloudWatch alarms** (free)
- **VPC and networking** (free)
- **ALB** (NOT free - $16/month)

### Create Account
1. Go to: https://aws.amazon.com/free/
2. Click "Create a free account"
3. Enter email and password
4. Verify email
5. Enter credit card (won't be charged if you stay within free tier)
6. Complete identity verification

---

## Step 2: EC2 Key Pair (Choose One Option)

### **OPTION A: Let Terraform Generate the Key (Easiest!)**
No manual AWS key creation needed. Skip to Step 3 and leave `key_name` empty in `terraform.tfvars`.
Terraform will:
1. Generate an RSA keypair locally
2. Create an AWS key pair
3. Save the private key as `AWS-IAC_generated_key.pem` in your workspace
4. Automatically use it for EC2 instances

You'll SSH using: `ssh -i AWS-IAC_generated_key.pem ec2-user@<public-ip>`

---

### **OPTION B: Create Key Manually in AWS (If you prefer)**

#### Option B.1: Using AWS CloudShell (Recommended if manual)
```bash
# 1. Log in to AWS Console
# 2. Click CloudShell icon (>_) in top right
# 3. Run this command:
aws ec2 create-key-pair --key-name terraform-key --region us-east-2 --query 'KeyMaterial' --output text > terraform-key.pem

# 4. Verify file was created:
ls -lah terraform-key.pem
```

#### Option B.2: Using AWS Console
1. Go to **EC2 Dashboard** → **Key Pairs**
2. Click **Create key pair**
3. Name it: `terraform-key` (or any name you prefer)
4. Format: **.pem** (for Mac/Linux) or **.ppk** (for Windows PuTTY)
5. Click **Create key pair**
6. Your browser downloads the `.pem` file
7. Keep this file safe!
8. In Step 3, set `key_name = "terraform-key"` in `terraform.tfvars` (use whatever name you chose)

---

## Step 3: Create terraform.tfvars (3 minutes)

This file tells Terraform your AWS settings.

### Steps:
1. Open the workspace folder in VS Code
2. Create a new file: `terraform.tfvars`
3. Paste this content:

```hcl
region        = "us-east-2"
instance_type = "t2.micro"
project       = "AWS-IAC"
# Leave AMI blank to auto-select latest Amazon Linux 2 for your region
AMI           = ""
# Leave key_name blank to let Terraform generate a key pair, or set to your AWS key pair name
key_name      = ""
```

4. Save the file

**That's it!** The values are already correct for free tier.

---

## Step 4: Install Terraform (5 minutes)

### Windows:
```powershell
# Using Chocolatey (if installed)
choco install terraform

# OR manually:
# 1. Go to https://www.terraform.io/downloads.html
# 2. Download for Windows
# 3. Extract and add to PATH
# 4. Restart terminal

# Verify installation
terraform --version
```

### macOS:
```bash
# Using Homebrew
brew install terraform

# Verify
terraform --version
```

### Linux (Ubuntu/Debian):
```bash
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform --version
```

---

## Step 5: Configure AWS Credentials (10 minutes)

### Why?
Terraform needs permission to create AWS resources using your credentials.

### Option A: AWS CloudShell (Easiest - No Setup!)
```bash
# CloudShell automatically has credentials
# Just run terraform commands directly
# Skip to Step 6!
```

### Option B: AWS CLI (Recommended)

#### Step 5.1: Create Access Keys in AWS Console
```
1. Log in to AWS Console
2. Go to IAM → Users → [Your User] or Create User
3. Go to Security Credentials tab
4. Click "Create access key"
5. Download CSV file with:
   - Access Key ID
   - Secret Access Key
6. Keep this file safe!
```

#### Step 5.2: Configure AWS CLI
```bash
# Run this command
aws configure

# When prompted, enter:
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
Default region name [None]: us-east-2
Default output format [None]: json

# Verify configuration
aws sts get-caller-identity
```

**Output should show your AWS account:**
```json
{
    "UserId": "...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### Option C: Using Environment Variables
```bash
# Windows PowerShell:
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_DEFAULT_REGION = "us-east-2"

# macOS/Linux:
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="us-east-2"
```

---

## Step 6: Deploy Infrastructure! 🚀 (5-15 minutes)

### Step 6.1: Initialize Terraform
```bash
# Open terminal in the AWS-IAC directory
cd /path/to/AWS-IAC

# Initialize Terraform (downloads AWS provider)
terraform init
```

**Output:**
```
Initializing the backend...
Successfully configured the backend "s3"!

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the terraform cache...
- Reusing previous version of hashicorp/random from the terraform cache...

Terraform has been successfully configured!
```

✅ **Success if:** No errors shown

### Step 6.2: Validate Configuration
```bash
terraform validate
```

**Output:**
```
Success! The configuration is valid.
```

### Step 6.3: Preview Changes
```bash
terraform plan
```

**Output shows:**
```
Plan: 30 to add, 0 to change, 0 to destroy.
```

**Review the plan carefully!** This shows everything that will be created.

### Step 6.4: Create Infrastructure
```bash
terraform apply
```

**When prompted:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```

**Type: `yes` and press Enter**

**Wait 5-15 minutes** for resources to be created. You'll see:
```
aws_vpc.main_vpc: Creating...
aws_security_group.alb_sg: Creating...
aws_s3_bucket.logs: Creating...
...
Apply complete! Resources: 30 added, 0 changed, 0 destroyed.
```

### Step 6.5: Get Your URLs and IPs
```bash
terraform output
```

**Output:**
```
alb_dns_name = "alb-aws-iac-123456.us-east-2.elb.amazonaws.com"
public_ec2_ip = "54.123.45.67"
private_ec2_ip = "10.0.2.45"
s3_bucket_name = "ec2-logs-abc123def456"
vpc_id = "vpc-0123456789abcdef0"
```

---

## Step 7: Test Your Deployment ✅

### 7.1: SSH into Public EC2 Instance
```bash
# Get the public IP from terraform output
PUBLIC_IP="54.123.45.67"  # Replace with actual IP

# SSH into instance (if you created a key manually):
ssh -i terraform-key.pem ec2-user@$PUBLIC_IP

# If Terraform generated the key (left key_name blank), use the generated PEM:
# ssh -i AWS-IAC_generated_key.pem ec2-user@$PUBLIC_IP

# Expected output: You're logged in!
[ec2-user@ip-10-0-1-5 ~]$
```

### 7.2: Check Tomcat is Running
```bash
# On the EC2 instance
curl http://localhost:8080/

# Output should show:
Hello from Terraform
```

### 7.3: Check Logs in S3
```bash
# On your local machine
aws s3 ls

# Output shows your bucket:
2024-01-15 10:30:45 ec2-logs-abc123def456
```

### 7.4: Check CloudWatch Alarms
```
1. Go to AWS Console
2. CloudWatch → Alarms
3. Should see:
   - CPUUtilization-Public-EC2
   - CPUUtilization-Private-EC2
```

### 7.5: Check Load Balancer
```
1. Go to AWS Console
2. EC2 → Load Balancers
3. Should see: alb-AWS-IAC
4. DNS name: alb-aws-iac-123456.us-east-2.elb.amazonaws.com
5. Visit this URL in browser → Should show "Hello from Terraform"
```

---

## Troubleshooting Common Issues

### Issue 1: "terraform: command not found"
**Solution:**
```bash
# Terraform not installed or not in PATH
# Reinstall and add to PATH
# Restart terminal after installation
```

### Issue 2: "error reading S3 backend config"
**Solution:**
```bash
# S3 backend bucket doesn't exist
# Comment out backend.tf temporarily:
# - Remove or comment the whole terraform { backend "s3" { } } block
# Apply again
```

### Issue 3: "Authorization failed - invalid credentials"
**Solution:**
```bash
# AWS credentials not configured
# Run: aws configure
# Or check env variables: echo $AWS_ACCESS_KEY_ID
```

### Issue 4: "Key 'terraform-key' does not exist"
**Solution:**
```bash
# Key pair not created in AWS
# Create it:
aws ec2 create-key-pair --key-name terraform-key --region us-east-2
```
Or, leave `key_name` blank and Terraform will generate a key pair and save the private key locally.

### Issue 5: Cannot SSH to instance
**Solution:**
```bash
# Might take 2-3 minutes for instance to be ready
# Wait and try again
# OR check security group allows SSH:
# AWS Console → Security Groups → ec2-sg-AWS-IAC → Inbound Rules
```

### Issue 6: ALB shows "unhealthy" instances
**Solution:**
```bash
# Tomcat might still be starting (takes 1-2 minutes)
# Wait and refresh
# OR check Tomcat status:
ssh -i terraform-key.pem ec2-user@$PUBLIC_IP
systemctl status tomcat
```

---

## Cost Check (IMPORTANT!)

### What Will Cost You?
```
❌ ALB: $16.20/month (NOT free tier)
❌ NAT Gateway: ~$0.05-1/month (if instances transfer data)
✅ 2x EC2 t2.micro: Free (750 hours/month)
✅ 5GB S3: Free
✅ CloudWatch: Free
```

### Estimate
- **If you have ALB**: ~$16-20/month
- **To stay completely free**: Delete ALB (see below)

### Delete ALB to Save Money
```bash
# Remove ALB by editing alb.tf
# Delete everything and replace with:
# (Leave file empty or delete it)

# Then:
terraform plan    # Should show ALB will be destroyed
terraform apply

# Redeploy without ALB
```

---

## Clean Up (Delete Everything)

When you're done learning and want to delete all resources:

```bash
# Preview what will be deleted
terraform plan -destroy

# Delete everything
terraform destroy

# Type: yes when prompted

# This deletes:
# ✅ 2 EC2 instances
# ✅ VPC, subnets, IGW, NAT
# ✅ ALB
# ✅ S3 bucket
# ✅ CloudWatch alarms
# ✅ IAM users and groups
```

**Warning:** This is permanent! All data is lost.

---

## Next Learning Steps

### After Deployment:
1. ✅ Explore AWS Console to see resources
2. ✅ SSH into instances and explore Tomcat
3. ✅ Modify variable values and redeploy
4. ✅ Add new resources (RDS, Lambda, etc.)

### Advanced Topics:
1. **Terraform Modules** - Reusable code
2. **Workspaces** - Separate dev/staging/prod
3. **CI/CD Pipeline** - Automated deployments
4. **Terraform Cloud** - Team collaboration

---

## Quick Reference Commands

```bash
# Initialize (run once)
terraform init

# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Preview changes
terraform plan

# Apply changes
terraform apply

# See outputs
terraform output

# Destroy all
terraform destroy

# Delete specific resource
terraform destroy -target=aws_instance.public_ec2

# Get detailed logs
export TF_LOG=DEBUG
terraform apply
unset TF_LOG

# Check state
terraform state list
terraform state show aws_instance.public_ec2

# Get single output
terraform output -raw public_ec2_ip
```

---

## Support Resources

### AWS Documentation
- AWS Free Tier: https://aws.amazon.com/free/
- EC2 Documentation: https://docs.aws.amazon.com/ec2/
- VPC Documentation: https://docs.aws.amazon.com/vpc/

### Terraform Documentation
- Terraform Docs: https://www.terraform.io/docs
- AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

### YouTube Tutorials
- Search: "Terraform AWS Tutorial"
- Search: "AWS CloudFormation vs Terraform"

### Community
- Reddit: r/devops, r/aws
- Stack Overflow: Tag with `terraform` and `aws`

---

## Summary

🎉 **You now have:**
- ✅ Complete AWS infrastructure (VPC, EC2, ALB, S3)
- ✅ Infrastructure as Code (repeatable deployments)
- ✅ Understanding of Terraform basics
- ✅ Running Tomcat servers
- ✅ Log storage in S3
- ✅ Cloud monitoring with CloudWatch

**You're ready for the next learning steps!**

---

**Questions?** Check:
1. `README.md` - Detailed documentation
2. `VALIDATION_REPORT.md` - Issues and fixes
3. AWS Support - For AWS-specific questions
4. Terraform Documentation - For Terraform questions

Good luck! 🚀
