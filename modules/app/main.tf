# Find Amazon Linux 2 AMI (x86_64)
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data: install Apache and put a simple index page
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -xe
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    echo "<h1>CPMC App - $(hostname)</h1>" > /var/www/html/index.html
    systemctl start httpd
  EOF
}

resource "aws_launch_template" "app" {
  name_prefix   = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-app-"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    security_groups             = [var.security_group_id]
    associate_public_ip_address = false
  }

  user_data = base64encode(local.user_data)

  # >>> Part 2 Enhancement <<<
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # Enforce IMDSv2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-app"
      Role = "app"
    })
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_min_size
  health_check_type         = "EC2"

  # >>> KEY CHANGE: run across BOTH application subnets (multi-AZ) <<<
  vpc_zone_identifier       = var.subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Propagate Name tag to instances (optional: already covered via LT)
  tag {
    key                 = "Name"
    value               = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Attach the ASG to the ALB target group
resource "aws_autoscaling_attachment" "tg" {
  autoscaling_group_name = aws_autoscaling_group.app.name
  lb_target_group_arn   = var.target_group_arn
}
