# Creates the VPC. We'll attach subnets, IGW, NAT, and routing later.
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy

  # Name tag builds from project/environment for clarity and DR drills.
  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-vpc"
  })
}
