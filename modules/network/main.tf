locals {
  # Split subnets into public and private lists for route-table associations
  public_subnet_keys  = [for k, v in var.subnets : k if v.public]
  private_subnet_keys = [for k, v in var.subnets : k if v.public == false]
}

# -----------------------------
# Subnets (3 total)
# -----------------------------
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public # only true for the management (public) subnet

  tags = merge(
    var.tags,
    {
      # Example: cpmc-dev-subnet-management
      Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-subnet-${each.key}"
      Tier = each.value.public ? "public" : "private"
    }
  )
}

# -----------------------------
# Internet Gateway (for public subnet internet access)
# -----------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-igw"
    }
  )
}

# -----------------------------
# NAT Gateway (for private subnets outbound internet)
# Placed in the public (management) subnet, requires an Elastic IP
# -----------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-nat-eip"
    }
  )
}

# Chooses the public subnet ID for NAT placement
locals {
  public_subnet_id_for_nat = aws_subnet.this[local.public_subnet_keys[0]].id
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = local.public_subnet_id_for_nat

  tags = merge(
    var.tags,
    {
      Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-nat"
    }
  )
}

# -----------------------------
# Route tables
# -----------------------------

# Public route table: default route to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-rt-public"
    }
  )
}

resource "aws_route" "public_default_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Associate *all public subnets* with the public RT (here: just 'management')
resource "aws_route_table_association" "public_assoc" {
  for_each       = toset(local.public_subnet_keys)
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.this[each.key].id
}

# Private route table: default route to NAT Gateway
# (We use a single private RT for both private subnets to keep it simple.)
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-rt-private"
    }
  )
}

resource "aws_route" "private_default_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

# Associate *all private subnets* with the private RT (application + backend)
resource "aws_route_table_association" "private_assoc" {
  for_each       = toset(local.private_subnet_keys)
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.this[each.key].id
}
