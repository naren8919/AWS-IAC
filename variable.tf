variable "region" {
  default = "us-east-2"
}

variable "instance_type" {
  default = "t2.micro"

}

variable "project" {
  default = "AWS-IAC"

}

variable "AMI" {
  # Leave blank to auto-select latest Amazon Linux 2 AMI for the region
  default = ""

}

variable "key_name" {
  description = "EC2 key pair name"
  default     = ""

}