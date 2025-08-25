# Map of subnet IDs by logical name
output "subnet_ids" {
  description = "Subnet IDs keyed by logical name"
  value       = { for k, s in aws_subnet.this : k => s.id }
}

# Public/Private route tables by AZ
output "public_route_table_ids_by_az" {
  description = "Public route table IDs keyed by AZ"
  value       = { for az, rt in aws_route_table.public : az => rt.id }
}

output "private_route_table_ids_by_az" {
  description = "Private route table IDs keyed by AZ"
  value       = { for az, rt in aws_route_table.private : az => rt.id }
}

# NAT gateways by AZ
output "nat_gateway_ids_by_az" {
  description = "NAT Gateway IDs keyed by AZ"
  value       = { for az, nat in aws_nat_gateway.this : az => nat.id }
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}
