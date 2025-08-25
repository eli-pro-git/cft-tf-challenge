# Bastion SG: only SSH from your IP. Egress all so you can update/install tools.
resource "aws_security_group" "bastion" {
  name        = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-bastion-sg"
  description = "Bastion host security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-bastion-sg"
  })
}

# Ingress: SSH from your IP only
resource "aws_security_group_rule" "bastion_ssh_in" {
  type              = "ingress"
  description       = "Allow SSH from operator IP"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.bastion_allowed_ssh_cidr]
  security_group_id = aws_security_group.bastion.id
}

# Egress: all traffic (so the bastion can reach Internet / VPC)
resource "aws_security_group_rule" "bastion_egress_all" {
  type              = "egress"
  description       = "Allow all egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

# Application SG: No public access. We'll add:
#  - SSH from bastion SG (this step)
#  - HTTP from ALB SG (next step)
resource "aws_security_group" "app" {
  name        = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-app-sg"
  description = "Application instances security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-app-sg"
  })
}

# Ingress: SSH from bastion SG only
resource "aws_security_group_rule" "app_ssh_from_bastion" {
  type                     = "ingress"
  description              = "Allow SSH from bastion"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.app.id
}

# Egress: all traffic (so app instances can reach outside via NAT)
resource "aws_security_group_rule" "app_egress_all" {
  type              = "egress"
  description       = "Allow all egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

# --- ADD: ALB Security Group ---
resource "aws_security_group" "alb" {
  name        = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-alb-sg"
  description = "ALB security group (internal)"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-alb-sg"
  })
}

# Ingress for ALB:
# Keep this tight: allow HTTP from the bastion SG (so you can test via bastion or port-forward).
resource "aws_security_group_rule" "alb_http_in_from_bastion" {
  type                     = "ingress"
  description              = "HTTP 80 from bastion only"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.alb.id
}

# Egress from ALB to anywhere (the app SG rule will constrain who can accept).
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  description       = "Allow all egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# --- UPDATE: App SG needs HTTP from ALB SG ---
resource "aws_security_group_rule" "app_http_from_alb" {
  type                     = "ingress"
  description              = "HTTP 80 from ALB only"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
}

# # TEMP TEST RULE: Allow HTTP 80 from bastion directly to app (bypassing ALB)
# resource "aws_security_group_rule" "app_http_from_bastion_temp" {
#   count                   = var.enable_temp_http_from_bastion ? 1 : 0
#   type                    = "ingress"
#   description             = "TEMP: HTTP 80 from bastion (no ALB available)"
#   from_port               = 80
#   to_port                 = 80
#   protocol                = "tcp"
#   source_security_group_id= aws_security_group.bastion.id
#   security_group_id       = aws_security_group.app.id
# }