# IAM Role for EC2 to access S3
resource "aws_iam_role" "ec2_s3_role" {
  name = "EC2-S3-Role-${var.project}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "EC2-S3-Role"
    Project = var.project
  }
}

# IAM Policy for EC2 to read/write to S3
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "EC2-S3-Policy-${var.project}"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      }
    ]
  })
}

# Instance Profile for attaching role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-Profile-${var.project}"
  role = aws_iam_role.ec2_s3_role.name
}
