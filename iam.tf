#Admin group
resource "aws_iam_group" "admin_group" {
  name = "AdminGroup"

}

resource "aws_iam_group_policy_attachment" "admin_group_policy_attach" {
  group      = aws_iam_group.admin_group.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

}

#Read only group
resource "aws_iam_group" "read_only_group" {
  name = "ReadOnly-ec2-Group"

}

resource "aws_iam_policy" "read_only_ec2_policy" {
  name        = "ReadOnlyEC2Policy"
  description = "Read only access to EC2 resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_group_policy_attachment" "read_only_group_policy_attach" {
  group      = aws_iam_group.read_only_group.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"

}

#Users  
resource "aws_iam_user" "Narendiran" {
  name = "Narendiran"

}

resource "aws_iam_user" "Narain" {
  name = "Narain"

}

resource "aws_iam_user_group_membership" "narendiran_map" {
  user   = aws_iam_user.Narendiran.name
  groups = [aws_iam_group.admin_group.name]
}

resource "aws_iam_user_group_membership" "narain_map" {
  user   = aws_iam_user.Narain.name
  groups = [aws_iam_group.read_only_group.name]

}