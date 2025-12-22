# Pre-Deployment Checklist

Use this checklist before running `terraform apply`

## Prerequisites ✓

### AWS Account Setup
- [ ] AWS Free Tier account created
- [ ] Confirmed you're using us-east-2 region
- [ ] Reviewed free tier costs (especially ALB)
- [ ] Understood you'll need a valid credit card (not charged if within free tier)

### Local Machine Setup
- [ ] Terraform installed (`terraform --version` works)
- [ ] AWS CLI installed (`aws --version` works)
- [ ] Text editor with Terraform syntax highlighting (VS Code recommended)
- [ ] Git installed for version control (optional but recommended)

### AWS Credentials
- [ ] AWS Access Key ID and Secret Access Key obtained
- [ ] AWS CLI configured (`aws configure` completed)
- [ ] Credentials verified (`aws sts get-caller-identity` works)
- [ ] OR CloudShell available in your AWS region

### EC2 Key Pair
- [ ] Key pair created in AWS (`terraform-key`)
- [ ] `.pem` file downloaded and saved securely
- [ ] File permissions set (`chmod 400 terraform-key.pem` on Unix)
- [ ] File kept in secure location (not in Git)

---

## Terraform Files ✓

### Files in Workspace
Verify all these files exist:
- [ ] `alb.tf` (load balancer configuration)
- [ ] `backend.tf` (state management)
- [ ] `cloudwatch.tf` (monitoring)
- [ ] `ec2.tf` (compute instances)
- [ ] `ec2-iam-role.tf` (IAM role for EC2) **[NEW]**
- [ ] `iam.tf` (users and groups)
- [ ] `output.tf` (output values)
- [ ] `provider.tf` (AWS provider)
- [ ] `S3.tf` (object storage)
- [ ] `sg.tf` (security groups) **[NEW]**
- [ ] `user-data.sh` (EC2 startup script)
- [ ] `variable.tf` (variable definitions)
- [ ] `vpc.tf` (networking)

### Configuration Files
- [ ] `terraform.tfvars` created (copy from `terraform.tfvars.example`)
- [ ] `terraform.tfvars` has correct `key_name` value
- [ ] `.gitignore` includes `terraform.tfvars` and `.terraform/`
- [ ] `README.md` reviewed for architecture understanding

### Documentation Files
- [ ] `README.md` - For comprehensive info
- [ ] `QUICKSTART.md` - For deployment steps
- [ ] `VALIDATION_REPORT.md` - For issue details
- [ ] `REVIEW_SUMMARY.md` - For overview

---

## Configuration Values ✓

### Variables
Check `terraform.tfvars`:
```
region        = "us-east-2"           ✓ Correct
instance_type = "t2.micro"            ✓ Free tier
project       = "AWS-IAC"             ✓ Correct
AMI           = "ami-068c0051b15cdb816"  ✓ Amazon Linux 2
key_name      = "terraform-key"       ✓ Must match your key pair
```

### Network Configuration
- [ ] VPC CIDR: `10.0.0.0/16` ✓
- [ ] Public Subnet: `10.0.1.0/24` ✓
- [ ] Private Subnet: `10.0.2.0/24` ✓
- [ ] No conflicts with existing VPCs

### Security
- [ ] ALB allows HTTP (80) ✓
- [ ] EC2 allows SSH (22) ✓
- [ ] EC2 allows Tomcat (8080) ✓
- [ ] SSH security group not too permissive (0.0.0.0/0 only for learning)

### IAM
- [ ] Admin group created ✓
- [ ] Read-only group created ✓
- [ ] User "Naren" mapped to admin ✓
- [ ] User "Narain" mapped to read-only ✓
- [ ] EC2 IAM role has S3 permissions ✓

---

## File Syntax ✓

### Terraform Syntax
- [ ] All `.tf` files have valid HCL syntax
- [ ] No unmatched quotes or brackets
- [ ] All resource references use correct names
- [ ] Variable interpolation correct (`${var.project}`)

### JSON Policy Files
- [ ] IAM policies have valid JSON syntax
- [ ] All Action values are lowercase (e.g., `s3:`, not `S3:`)
- [ ] Statement arrays properly closed
- [ ] No trailing commas in JSON

### Bash Script
- [ ] `user-data.sh` is valid bash script
- [ ] `${bucket_name}` template variable will be replaced
- [ ] Script has execute permissions (not required for user-data)

---

## Resource Planning ✓

### Resources to be Created
Review that terraform will create:
- [ ] 1 VPC
- [ ] 2 Subnets (public + private)
- [ ] 1 Internet Gateway
- [ ] 1 Elastic IP (for NAT)
- [ ] 1 NAT Gateway
- [ ] 2 Route Tables
- [ ] 2 Route Table Associations
- [ ] 2 Security Groups (ALB + EC2)
- [ ] 2 EC2 Instances
- [ ] 1 ALB (Application Load Balancer)
- [ ] 1 Target Group
- [ ] 1 Target Group Attachment
- [ ] 1 ALB Listener
- [ ] 1 S3 Bucket
- [ ] 2 CloudWatch Alarms
- [ ] 1 IAM Role
- [ ] 1 IAM Role Policy
- [ ] 1 IAM Instance Profile
- [ ] 2 IAM Groups
- [ ] 2 IAM Users
- [ ] 2 IAM Group Memberships

**Total: ~30 resources**

---

## Cost Estimation ✓

### Monthly Cost Breakdown
- [ ] Understood 2x t2.micro EC2 are **free** ($0/month)
- [ ] Understood 5GB S3 is **free** ($0/month)
- [ ] Understood CloudWatch is **free** ($0/month)
- [ ] **ALB costs $16.20/month** (NOT free - can delete if needed)
- [ ] NAT Gateway will cost ~$0.05-0.50/month (small data)

### Budget Planning
- [ ] Comfortable with ~$16-20/month charges (ALB + NAT)
- [ ] OR willing to delete ALB to stay completely free
- [ ] Can delete all resources when learning is done

---

## Deployment Steps ✓

### Pre-Apply
- [ ] Working directory is `c:\Users\Naren DI\Documents\AWS-IAC`
- [ ] Have AWS credentials configured
- [ ] Have EC2 key pair created
- [ ] Have terraform.tfvars file with correct key_name

### Ready to Execute
- [ ] Ready to run: `terraform init`
- [ ] Ready to run: `terraform validate`
- [ ] Ready to run: `terraform plan`
- [ ] Ready to run: `terraform apply`

### After Apply
- [ ] Will check terraform outputs
- [ ] Will test SSH to public instance
- [ ] Will verify Tomcat is running
- [ ] Will check ALB DNS
- [ ] Will cleanup if needed

---

## Important Notes ✓

### Do NOT Do These:
- [ ] ❌ Don't commit `terraform.tfvars` to Git (has sensitive data)
- [ ] ❌ Don't change state file manually
- [ ] ❌ Don't deploy without reviewing `terraform plan` first
- [ ] ❌ Don't share AWS credentials with others
- [ ] ❌ Don't leave infrastructure running if you're not using it

### Do These:
- [ ] ✅ Review terraform plan output carefully
- [ ] ✅ Backup your key pair file securely
- [ ] ✅ Keep terraform.tfvars in .gitignore
- [ ] ✅ Run terraform destroy when learning is complete
- [ ] ✅ Check AWS Console to verify resources were created
- [ ] ✅ Monitor CloudWatch for cost increases

---

## Support Resources ✓

### In Case of Issues
- [ ] Have README.md open for reference
- [ ] Have QUICKSTART.md for step-by-step help
- [ ] Have VALIDATION_REPORT.md for issue details
- [ ] Know how to check AWS CloudFormation events
- [ ] Know how to check terraform logs (`TF_LOG=DEBUG`)

### Contact Points
- [ ] Bookmark Terraform docs: terraform.io/docs
- [ ] Bookmark AWS docs: docs.aws.amazon.com
- [ ] Know where to find AWS support
- [ ] Have example troubleshooting steps ready

---

## Verification Before Running Apply

### Final System Check
```bash
# In your terminal:
$ terraform --version
Terraform v1.x.x

$ aws --version
aws-cli/2.x.x

$ aws sts get-caller-identity
{
    "Account": "123456789012",
    ...
}

$ ls terraform.tfvars
terraform.tfvars

$ ls *.tf
alb.tf  backend.tf  cloudwatch.tf  ec2-iam-role.tf ...
```

All outputs above should show **no errors**. ✅

---

## Deployment Sequence

### Step 1: Initialize (2 min)
```bash
terraform init
# Downloads providers and prepares .terraform directory
# Output: "Terraform has been successfully configured!"
```

### Step 2: Validate (1 min)
```bash
terraform validate
# Checks syntax of all .tf files
# Output: "Success! The configuration is valid."
```

### Step 3: Plan (2 min)
```bash
terraform plan -out=tfplan
# Preview all changes before applying
# Output: "Plan: 30 to add, 0 to change, 0 to destroy."
# REVIEW THIS CAREFULLY!
```

### Step 4: Apply (10-15 min)
```bash
terraform apply tfplan
# Actually creates all resources in AWS
# Watch the progress
# Output: "Apply complete! Resources: 30 added."
```

### Step 5: Capture Outputs (1 min)
```bash
terraform output
# Shows:
# - alb_dns_name
# - public_ec2_ip
# - s3_bucket_name
# - etc.
```

**Total Time: ~20-30 minutes**

---

## Post-Deployment Verification ✓

After `terraform apply` succeeds:

### AWS Console Checks
- [ ] Go to EC2 → Instances: See 2 instances (running)
- [ ] Go to VPC: See your VPC with correct CIDR
- [ ] Go to S3: See bucket created with random name
- [ ] Go to ALB: See load balancer with DNS name
- [ ] Go to CloudWatch: See 2 alarms created
- [ ] Go to IAM: See 2 users and 2 groups

### SSH Test
```bash
PUBLIC_IP=$(terraform output -raw public_ec2_ip)
ssh -i terraform-key.pem ec2-user@$PUBLIC_IP  # or use AWS-IAC_generated_key.pem if Terraform generated the key
# Should connect successfully
```

### Tomcat Test
```bash
# On the EC2 instance:
curl http://localhost:8080/
# Should output: "Hello from Terraform"
```

### ALB Test
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
# Copy to browser: http://$ALB_DNS
# Should show: "Hello from Terraform"
```

---

## Cleanup Instructions

When you're done learning:

```bash
# Preview what will be deleted
terraform plan -destroy

# Delete all resources
terraform destroy

# Confirm by typing 'yes'

# Verify in AWS Console that resources are gone
# This takes 5-10 minutes
```

**WARNING:** This is permanent! All data is deleted.

---

## Final Readiness

- [ ] All checklist items completed ✓
- [ ] All files in place ✓
- [ ] Credentials configured ✓
- [ ] Key pair created ✓
- [ ] Cost implications understood ✓
- [ ] Documentation reviewed ✓

**✅ YOU ARE READY TO DEPLOY!**

---

## Deployment Command

When everything above is checked:

```bash
cd "c:\Users\Naren DI\Documents\AWS-IAC"
terraform init && terraform validate && terraform plan -out=tfplan && terraform apply tfplan
```

Or step by step (safer):

```bash
cd "c:\Users\Naren DI\Documents\AWS-IAC"
terraform init
terraform validate
terraform plan -out=tfplan
# Review the plan output
terraform apply tfplan
```

---

**Good luck! You've got this! 🚀**

For any issues, check:
1. QUICKSTART.md - Beginner guide
2. README.md - Full documentation
3. VALIDATION_REPORT.md - Technical details
4. AWS Console - Verify resource status

