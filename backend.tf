# terraform {
#   backend "s3" {
#     bucket = "terraform-remote-state-naren"
#     key = "non-module/terraform.tfstate"
#     region = "us-east-2"
#   }
# }

# NOTE: S3 backend disabled for local development
# Uncomment above after setting up AWS credentials and S3 bucket
# For local state: terraform.tfstate file will be created in project directory