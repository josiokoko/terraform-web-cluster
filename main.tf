provider "aws" {
  region = "us-east-1"
}


resource "aws_instance" "web_server" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  user_data              = file("scripts/app.sh")
  vpc_security_group_ids = [aws_security_group.web_ec2_sg.id]

  tags = {
    Name = "web-server-${terraform.workspace}"
  }
}


resource "aws_security_group" "web_ec2_sg" {
  name = "web-instance-sg"

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


resource "aws_launch_configuration" "l_config" {
  image_id        = "ami-0c02fb55956c7d316"
  instance_type   = var.ec2_instance_type
  user_data       = file("scripts/app.sh")
  security_groups = [aws_security_group.web_ec2_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "web_asg" {
  launch_configuration = aws_launch_configuration.l_config.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  min_size             = 2
  max_size             = 5

  tag {
    key                 = "Name"
    value               = "web-server-${terraform.workspace}"
    propagate_at_launch = true
  }
}