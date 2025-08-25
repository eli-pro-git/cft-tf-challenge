output "flow_log_id" {
  description = "ID of the VPC flow log"
  value       = aws_flow_log.vpc.id
}

output "log_group_name" {
  description = "CloudWatch Log Group receiving flow logs"
  value       = aws_cloudwatch_log_group.vpc_fl.name
}

output "iam_role_arn" {
  description = "IAM role used by Flow Logs"
  value       = aws_iam_role.flow_logs_role.arn
}
