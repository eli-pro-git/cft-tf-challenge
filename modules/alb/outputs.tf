output "alb_arn" {
  value       = aws_lb.this.arn
  description = "ALB ARN"
}

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "ALB DNS name (internal)"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "App target group ARN"
}
