# Internal ALB (not internet-facing). Requires >= 2 subnets in different AZs.
resource "aws_lb" "this" {
  name               = substr("${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-alb", 0, 32)
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-alb"
  })
}

# Target group for HTTP to the app instances
resource "aws_lb_target_group" "app" {
  name        = substr("${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-tg", 0, 32)
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-tg"
  })
}

# HTTP listener forwards to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
