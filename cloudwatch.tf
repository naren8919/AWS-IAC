resource "aws_cloudwatch_metric_alarm" "cpu_utilization_public" {
  alarm_name          = "CPUUtilization-Public-EC2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when CPU exceeds 80% for public EC2"
  dimensions = {
    InstanceId = aws_instance.public_ec2.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_private" {
  alarm_name          = "CPUUtilization-Private-EC2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when CPU exceeds 80% for private EC2"
  dimensions = {
    InstanceId = aws_instance.private_ec2.id
  }
}