resource "aws_instance" "public_ec2" {
  ami                    = var.AMI != "" ? var.AMI : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  key_name               = var.key_name != "" ? var.key_name : aws_key_pair.generated.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/user-data.sh", {
    bucket_name = aws_s3_bucket.logs.bucket
  })

  tags = {
    Name    = "Public-EC2-Instance"
    Project = var.project
  }

}

resource "aws_instance" "private_ec2" {
  ami                    = var.AMI != "" ? var.AMI : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  key_name               = var.key_name != "" ? var.key_name : aws_key_pair.generated.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/user-data.sh", {
    bucket_name = aws_s3_bucket.logs.bucket
  })

  tags = {
    Name    = "Private-EC2-Instance"
    Project = var.project
  }

}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}