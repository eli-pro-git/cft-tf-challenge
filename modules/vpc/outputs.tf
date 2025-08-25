output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The VPC CIDR"
  value       = aws_vpc.this.cidr_block
}

output "vpc_arn" {
  description = "The VPC ARN"
  value       = aws_vpc.this.arn
}
