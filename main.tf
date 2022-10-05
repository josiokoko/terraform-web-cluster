provider "aws" {
  region = "us-east-1"
}


resource "aws_launch_configuration" "l_config" {
  image_id        = var.web_amis[var.region]
  instance_type   = var.ec2_instance_type
  user_data       = file("scripts/app.sh")
  security_groups = [aws_security_group.web_ec2_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.l_config.name
  vpc_zone_identifier  = local.public_subnets_ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "web-server-${terraform.workspace}"
    propagate_at_launch = true
  }
}


resource "aws_security_group" "web_ec2_sg" {
  name   = "web-instance-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description = "Accept incoming traffic from anywhere"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}


#################################################
#### Application Load Balancer ##################
#################################################

resource "aws_lb" "web_cluster" {
  name               = "wb-cluster-lb"
  load_balancer_type = "application"
  subnets            = local.public_subnets_ids
  security_groups    = [aws_security_group.alb.id]
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_cluster.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found!"
      status_code  = "404"
    }
  }
}


resource "aws_security_group" "alb" {
  name   = "alb-security-group"
  vpc_id = aws_vpc.main_vpc.id

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outgoing requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group-${terraform.workspace}"
  }
}



resource "aws_lb_target_group" "asg" {
  name     = "web-cluster-lb-alb-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}