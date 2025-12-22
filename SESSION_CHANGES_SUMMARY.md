# Session Changes Summary — December 2025

## Overview
This document summarizes all code and documentation changes made to the AWS-IAC Terraform project in this session. The changes address three critical deployment issues:
1. **Multi-AZ VPC Architecture** — convert single subnets to span two availability zones
2. **AMI Auto-Selection** — use a data source to fetch the latest Amazon Linux 2 AMI for the region instead of hard-coded IDs
3. **Automatic Key Pair Generation** — allow Terraform to generate an SSH keypair automatically instead of requiring pre-creation

---

## 1. Multi-AZ VPC Architecture Changes

### Problem
- Original design had single public and private subnets
- ALB (Application Load Balancer) failed to deploy: _"A load balancer cannot be attached to multiple subnets in the same Availability Zone"_
- ALB requires at least two subnets in different AZs
- Single AZ setup creates a single point of failure

### Solution
Convert VPC subnets to span two availability zones using `count`.

### Files Modified

#### `vpc.tf` (Major Updates)
**Added:**
- `data.aws_availability_zones.available` — queries available AZs for the region
- `aws_subnet.public` (count = 2) — creates 2 public subnets across different AZs
- `aws_subnet.private` (count = 2) — creates 2 private subnets across different AZs
- CIDR subnets calculated using `cidrsubnet()`:
  - Public: 10.0.1.0/24 (AZ 0) and 10.0.3.0/24 (AZ 1)
  - Private: 10.0.2.0/24 (AZ 0) and 10.0.4.0/24 (AZ 1)
- NAT Gateway placement in `aws_subnet.public[0]` (first public subnet)
- Route table associations using `count`:
  - `aws_route_table_association.public_rt_assoc` (count = 2)
  - `aws_route_table_association.private_rt_assoc` (count = 2)

**Changed:**
- NAT Gateway references: `aws_subnet.public[0].id` (indexed reference)

#### `ec2.tf` (References Updated)
**Changed:**
```hcl
# Before:
subnet_id = aws_subnet.public.id
subnet_id = aws_subnet.private.id

# After:
subnet_id = aws_subnet.public[0].id
subnet_id = aws_subnet.private[0].id
```
- Both public and private EC2 instances reference the first subnet in each count (scalable, but ALB will use all subnets)

#### `alb.tf` (Subnet Lists Updated)
**Changed:**
```hcl
# Before:
subnets = [aws_subnet.public.id, aws_subnet.private.id]  # Mixed AZs, single instance each
subnets = [aws_subnet.private.id]

# After:
subnets = aws_subnet.public[*].id   # All public subnets (multi-AZ)
subnets = aws_subnet.private[*].id  # All private subnets (multi-AZ)
```
- ALB now spans both public subnets (different AZs) — resolves deployment error
- Private ALB spans both private subnets

#### `output.tf` (Subnet Output Lists)
**Changed:**
```hcl
# Before:
output "public_subnet_id" {
  value = aws_subnet.public.id
}

# After:
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
  description = "List of public subnet IDs (multi-AZ)"
}
```

---

## 2. AMI Auto-Selection with Data Source

### Problem
- Hard-coded AMI: `ami-068c0051b15cdb816`
- EC2 creation failed: _"InvalidAMIID.NotFound: The image id 'ami-068c0051b15cdb816' does not exist"_
- AMI IDs are region-specific; hard-coded IDs don't work across regions
- User had no easy way to find the correct AMI for their region

### Solution
Use Terraform `data.aws_ami` to dynamically lookup the latest Amazon Linux 2 AMI for the chosen region.

### Files Modified

#### `variable.tf` (AMI Default Cleared)
**Changed:**
```hcl
# Before:
variable "AMI" {
  default = "ami-068c0051b15cdb816"
}

# After:
variable "AMI" {
  # Leave blank to auto-select latest Amazon Linux 2 AMI for the region
  default = ""
}
```

#### `ec2.tf` (AMI Data Source + Conditional Logic)
**Added:**
```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

**Changed (both instances):**
```hcl
# Before:
ami = var.AMI

# After:
ami = var.AMI != "" ? var.AMI : data.aws_ami.amazon_linux.id
```
- If user sets `var.AMI` to a specific value, use it
- Otherwise, dynamically lookup the latest Amazon Linux 2 AMI for the region
- Removes dependency on hard-coded, region-specific AMI IDs

---

## 3. Automatic SSH Key Pair Generation

### Problem
- User attempted apply without creating AWS key pair first
- Error: _"InvalidKeyPair.NotFound: The key pair 'terraform.key' does not exist"_
- Requires manual AWS CLI or console steps before Terraform apply
- Adds friction for new users in demo/learning environments

### Solution
Add Terraform resources to auto-generate an SSH keypair, create an AWS key pair, and save the private key locally.

### Files Created

#### `keypair.tf` (NEW FILE)
**Contains:**
```hcl
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated" {
  key_name_prefix = "${var.project}-key-"
  public_key      = tls_private_key.generated.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${path.module}/${var.project}_generated_key.pem"
  file_permission = "0600"
}

output "generated_key_name" {
  value       = aws_key_pair.generated.key_name
  description = "Name of the key pair created in AWS (when var.key_name is left blank)"
}

output "generated_private_key_path" {
  value       = local_file.private_key.filename
  description = "Local path where the generated private key PEM was saved"
  sensitive   = true
}
```

**Behavior:**
- Generates a 2048-bit RSA private key locally
- Uploads public key to AWS as `aws_key_pair` with name prefix `${project}-key-`
- Writes private key PEM to `${workspace}/${project}_generated_key.pem` with mode 0600
- Outputs the key name and path for reference

### Files Modified

#### `variable.tf` (Key Name Default Added)
**Changed:**
```hcl
# Before:
variable "key_name" {
  description = "EC2 key pair name"
}

# After:
variable "key_name" {
  description = "EC2 key pair name"
  default     = ""
}
```
- Empty default means no interactive prompt during plan
- User can leave blank to auto-generate or provide a name for an existing key

#### `ec2.tf` (Conditional Key Reference)
**Changed (both instances):**
```hcl
# Before:
key_name = var.key_name

# After:
key_name = var.key_name != "" ? var.key_name : aws_key_pair.generated.key_name
```
- If `var.key_name` is provided, use the existing key
- If `var.key_name` is empty, use the generated key

---

## 4. Documentation Updates

All documentation files updated to reflect the three major changes above.

### Files Updated

#### `terraform.tfvars.example`
**Updated:**
- AMI field now shows `""` with explanation of auto-selection
- Key name field now shows `""` with explanation of both options (auto-generate vs manual)
- Added detailed comments explaining each option

#### `README.md`
**Updated sections:**
- **Key Pair section (3. Create EC2 Key Pair)**
  - Added note explaining Terraform-generated keys as alternative
  - Explains file location: `${project}_generated_key.pem`
  - Shows how to use generated key for SSH
  
- **Variables section (### Variables)**
  - Clarified AMI field uses auto-selection when blank
  - Noted key generation as alternative

- **VPC Network section (### VPC Network)**
  - Changed from single subnets to multi-AZ: "2 public + 2 private across AZs"

#### `QUICKSTART.md`
**Updated sections:**
- **Step 2: EC2 Key Pair**
  - Reorganized into **OPTION A (Terraform Generation)** and **OPTION B (Manual)**
  - Recommends auto-generation for learning environments
  - Shows exact commands for manual creation if preferred

- **Step 3: Create terraform.tfvars**
  - Shows `key_name = ""` as example
  - Clarifies that leaving blank enables auto-generation

- **Step 7.1: SSH into Public EC2 Instance**
  - Shows both PEM file options:
    - `terraform-key.pem` for manually created keys
    - `AWS-IAC_generated_key.pem` for auto-generated keys

- **Troubleshooting → Issue 4**
  - Added note that leaving `key_name` blank lets Terraform generate the key

#### `VALIDATION_REPORT.md`
**Updated sections:**
- **Example NAT Gateway**
  - Changed from `aws_subnet.public.id` to `aws_subnet.public[0].id`
  - Added comment explaining multi-AZ indexing

- **Example Route Table Associations**
  - Shows count-based associations for both public and private subnets

- **Example Outputs**
  - Changed from single subnet IDs to lists: `public_subnet_ids` and `private_subnet_ids`

- **About SSH Access**
  - Added guidance on using generated key PEM file

#### `MISTAKES_AND_FIXES.md`
**Updated sections:**
- **Issue #3: Inconsistent Subnet Resource Names**
  - Clarified old mismatch and showed new multi-AZ references
  - Example: `subnet_id = aws_subnet.public[0].id` or `aws_subnet.public[*].id`

- **Issue #11: Route Table Associations**
  - Updated example to show count-based associations for multi-AZ

- **Issue #12: NAT Gateway**
  - Updated NAT gateway subnet reference to `aws_subnet.public[0].id`

#### `REVIEW_SUMMARY.md`
**Updated sections:**
- Example 4 (EC2 Instance) — subnet reference updated to `aws_subnet.public[0].id`
- Example 5 (NAT Gateway) — subnet reference updated to `aws_subnet.public[0].id`

#### `PREDEPLOYMENT_CHECKLIST.md`
- Added note that SSH can use `AWS-IAC_generated_key.pem` if Terraform generated the key

#### `FINAL_SUMMARY.md`
- SSH instructions now mention `AWS-IAC_generated_key.pem` as alternative

#### `START_HERE.md`
- SSH instructions updated to reference generated key option

---

## 5. Impact Summary

### Deployment Readiness
✅ **All blockers resolved:**
- ALB can now be deployed (multi-AZ subnets fix)
- EC2 instances use region-appropriate AMI (auto-selection)
- SSH key pair created automatically (no pre-requisite manual steps)

### User Experience Improvements
✅ **Simplified onboarding:**
- Users can now run `terraform plan` and `terraform apply` with minimal prerequisites
- No need to manually create AWS key pair or specify AMI
- Generated key file is automatically available for SSH

✅ **Backward compatibility:**
- Users can still provide their own key pair name (Option B)
- Users can still specify a custom AMI if needed
- Existing workflows continue to work

### Infrastructure Quality
✅ **Better production readiness:**
- Multi-AZ architecture improves availability
- ALB meets AWS requirements
- Dynamic AMI selection works across regions
- Proper security group and IAM configurations maintained

---

## Files Summary

### Code Files Modified (5)
1. `vpc.tf` — Multi-AZ subnets, data source for AZs, route table associations
2. `ec2.tf` — AMI data source, conditional key references, subnet indexing
3. `alb.tf` — Subnet list references for multi-AZ
4. `variable.tf` — AMI and key_name defaults
5. `output.tf` — Subnet ID lists for multi-AZ

### Code Files Created (1)
1. `keypair.tf` — SSH key generation, AWS key pair creation, local key storage

### Documentation Files Updated (11)
1. `terraform.tfvars.example` — AMI and key options explained
2. `README.md` — Key pair, variables, VPC network sections
3. `QUICKSTART.md` — Key pair setup, terraform.tfvars example, SSH instructions
4. `VALIDATION_REPORT.md` — Multi-AZ examples, SSH guidance
5. `MISTAKES_AND_FIXES.md` — Updated references and examples
6. `REVIEW_SUMMARY.md` — Updated code examples
7. `PREDEPLOYMENT_CHECKLIST.md` — SSH key guidance
8. `FINAL_SUMMARY.md` — SSH instructions
9. `START_HERE.md` — SSH instructions
10. (This document) `SESSION_CHANGES_SUMMARY.md` — New comprehensive summary

---

## Deployment Instructions (Updated)

### Quick Start
```bash
cd /path/to/AWS-IAC

# Initialize Terraform
terraform init

# Plan (will auto-generate key and lookup AMI)
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Get outputs including generated key path
terraform output
```

### Using Generated Key for SSH
```bash
# Terraform outputs will show the generated key location
# Typically: AWS-IAC_generated_key.pem

# SSH to public instance
PUBLIC_IP=$(terraform output -raw public_ec2_ip)
ssh -i AWS-IAC_generated_key.pem ec2-user@$PUBLIC_IP
```

### Using Your Own Key (Alternative)
If you prefer to use an existing AWS key pair:

```bash
# Create terraform.tfvars with your key name
cat > terraform.tfvars <<EOF
region        = "us-east-2"
instance_type = "t2.micro"
project       = "AWS-IAC"
AMI           = ""
key_name      = "your-existing-key-name"
EOF

# Then plan and apply as usual
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Testing Status

✅ **Terraform validate** — Configuration is syntactically valid
✅ **terraform plan** — Successfully generates plan without errors
✅ **terraform apply** — Executed successfully (Exit Code: 0)

All resources created:
- VPC with multi-AZ subnets
- Internet Gateway and NAT Gateway with Elastic IP
- 2 EC2 instances (public + private)
- ALB with target groups
- S3 bucket for logs
- IAM roles and security groups
- CloudWatch alarms
- Auto-generated SSH key pair

---

## Next Steps (For Users)

1. ✅ Review the changes in this summary
2. ✅ Use the simplified deployment process (auto-generation recommended)
3. ✅ SSH into instances using the generated key or your own
4. ✅ Verify infrastructure is running and healthy
5. ⏭️ Test application connectivity through ALB
6. ⏭️ Monitor logs in CloudWatch and S3
7. ⏭️ Clean up when done: `terraform destroy`

---

**Document Created:** December 19, 2025  
**Status:** ✅ All changes applied and validated
