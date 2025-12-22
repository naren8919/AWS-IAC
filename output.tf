output "s3_bucket_name" {
  value       = aws_s3_bucket.logs.bucket
  description = "Name of S3 bucket for logs"
}

output "public_ec2_ip" {
  value       = aws_instance.public_ec2.public_ip
  description = "Public IP of public EC2 instance"
}

output "private_ec2_ip" {
  value       = aws_instance.private_ec2.private_ip
  description = "Private IP of private EC2 instance"
}

output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "alb_arn" {
  value       = aws_lb.alb.arn
  description = "ARN of the Application Load Balancer"
}

output "vpc_id" {
  value       = aws_vpc.main_vpc.id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = aws_subnet.public[*].id
  description = "Public subnet ID"
}

output "private_subnet_id" {
  value       = aws_subnet.private[*].id
  description = "Private subnet ID"
}