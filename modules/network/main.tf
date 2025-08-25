locals {
  # Convenience splits
  public_subnet_keys  = [for k, v in var.subnets : k if v.public]
  private_subnet_keys = [for k, v in var.subnets : k if v.public == false]

  # All AZs used by the provided subnets (e.g., ["us-east-1a","us-east-1b"])
  azs = toset([for _, v in var.subnets : v.az])
}

# -----------------------------
# Subnets (6 total)
# -----------------------------
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public

  tags = merge(
    var.tags,
    {
      # Example: cpmc-dev-subnet-application_a
      Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-subnet-${each.key}"
      Tier = each.value.public ? "public" : "private"
      AZ   = each.value.az
    }
  )
}

# -----------------------------
# Internet Gateway
# -----------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    { Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-igw" }
  )
}

# -----------------------------
# NAT per AZ (requires public subnet in each AZ)
# -----------------------------
# Map: "us-east-1a" => <public-subnet-id-in-1a>, "us-east-1b" => <public-subnet-id-in-1b>
locals {
  public_subnet_id_by_az = {
    for k, s in aws_subnet.this :
    var.subnets[k].az => s.id
    if var.subnets[k].public
  }
}

# Allocate an EIP for each AZ's NAT
resource "aws_eip" "nat" {
  for_each = local.public_subnet_id_by_az
  domain   = "vpc"

  tags = merge(
    var.tags,
    { Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-nat-eip-${each.key}" }
  )
}

# Create a NAT Gateway in each AZ's public subnet
resource "aws_nat_gateway" "this" {
  for_each      = local.public_subnet_id_by_az
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value

  tags = merge(
    var.tags,
    { Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-nat-${each.key}" }
  )
}

# -----------------------------
# Route tables (per AZ)
# -----------------------------

# Public Route Table per AZ => default route to IGW
resource "aws_route_table" "public" {
  for_each = local.azs
  vpc_id   = var.vpc_id

  tags = merge(
    var.tags,
    { Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-rt-public-${each.key}" }
  )
}

resource "aws_route" "public_default_inet" {
  for_each                  = local.azs
  route_table_id            = aws_route_table.public[each.key].id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.this.id
}

# Associate each public subnet to its AZ's public route table
resource "aws_route_table_association" "public_assoc" {
  for_each = {
    for k in local.public_subnet_keys :
    k => {
      subnet_id = aws_subnet.this[k].id
      az        = var.subnets[k].az
    }
  }

  route_table_id = aws_route_table.public[each.value.az].id
  subnet_id      = each.value.subnet_id
}

# Private Route Table per AZ => default route to NAT in same AZ
resource "aws_route_table" "private" {
  for_each = local.azs
  vpc_id   = var.vpc_id

  tags = merge(
    var.tags,
    { Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-rt-private-${each.key}" }
  )
}

resource "aws_route" "private_default_nat" {
  for_each                  = local.azs
  route_table_id            = aws_route_table.private[each.key].id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.this[each.key].id
}

# Associate each private subnet to its AZ's private route table
resource "aws_route_table_association" "private_assoc" {
  for_each = {
    for k in local.private_subnet_keys :
    k => {
      subnet_id = aws_subnet.this[k].id
      az        = var.subnets[k].az
    }
  }

  route_table_id = aws_route_table.private[each.value.az].id
  subnet_id      = each.value.subnet_id
}
