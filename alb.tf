resource "aws_lb" "alb" {
  name               = "alb-${var.project}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name    = "ALB"
    Project = var.project
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg-${var.project}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name    = "App-Target-Group"
    Project = var.project
  }
}

# Register public EC2 instance with target group
resource "aws_lb_target_group_attachment" "public_instance" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.public_ec2.id
  port             = 8080
}

# ALB Listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb" "private_alb" {
  name               = "private-alb-${var.project}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.private[*].id

  tags = {
    Name    = "Private-ALB"
    Project = var.project
  }
}