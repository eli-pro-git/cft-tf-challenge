output "instance_profile_name" {
  description = "Name of the SSM instance profile"
  value       = aws_iam_instance_profile.ssm_profile.name
}

output "role_name" {
  description = "Name of the SSM role"
  value       = aws_iam_role.ssm_role.name
}
