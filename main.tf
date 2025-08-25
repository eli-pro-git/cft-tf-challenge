# S3 Bucket for project statefile
resource "aws_s3_bucket" "terraform_state" {
  bucket = "cfc-tf-state"
  
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Step 1 only creates the VPC. Subnets/IGW/NAT/Routes will come in next steps.
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = var.vpc_cidr

  # DNS is handy for private name resolution and future ALB targets.
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Standardized tags
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# --- Step 2: Network module (subnets + IGW + NAT + routes) ---

module "network" {
  source  = "./modules/network"

  vpc_id  = module.vpc.vpc_id
  subnets = var.subnets

  # Reuse the same tagging pattern; Name tags will be generated inside.
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Helpful root-level outputs (optional, for visibility)
output "subnet_ids" {
  description = "Subnet IDs by logical name"
  value       = module.network.subnet_ids
}

output "public_route_table_id" {
  value       = module.network.public_route_table_id
  description = "Route table used by the public (management) subnet"
}

output "private_route_table_id" {
  value       = module.network.private_route_table_id
  description = "Route table used by private subnets (application, backend)"
}

# --- Step 3: Security Groups (bastion + app) ---
module "security" {
  source = "./modules/security"

  vpc_id                    = module.vpc.vpc_id
  bastion_allowed_ssh_cidr  = var.bastion_allowed_ssh_cidr

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# --- Step 3: Bastion EC2 in public (management) subnet ---
module "bastion" {
  source = "./modules/bastion"

  subnet_id  = module.network.subnet_ids["management"]   # public subnet from Step 2
  sg_id      = module.security.bastion_sg_id             # SG created above
  key_name   = var.bastion_key_name
  # Instance type per requirements
  instance_type = "t2.micro"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Helpful outputs
output "bastion_public_ip" {
  description = "Public IP of the bastion"
  value       = module.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion"
  value       = module.bastion.private_ip
}

output "bastion_sg_id" {
  description = "Security Group ID for bastion"
  value       = module.security.bastion_sg_id
}

output "app_sg_id" {
  description = "Security Group ID for application instances"
  value       = module.security.app_sg_id
}

# --- Step 4B: ALB (internal) across application + backend subnets ---
module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  security_group_id = module.security.alb_sg_id
  # Two subnets in different AZs (required by ALB). Using your private subnets:
  subnet_ids = [
    module.network.subnet_ids["application"], # us-east-1b
    module.network.subnet_ids["backend"]      # us-east-1a
  ]

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# --- Step 4C: App (LT + ASG) in application subnet, attach to TG ---
module "app" {
  source = "./modules/app"

  subnet_id         = module.network.subnet_ids["application"]
  security_group_id = module.security.app_sg_id
  key_name          = var.bastion_key_name
  instance_type     = "t2.micro"   # per requirements
  asg_min_size      = 2            # per requirements
  asg_max_size      = 6            # per requirements

  target_group_arn  = module.alb.target_group_arn

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Helpful outputs
output "alb_dns_name" {
  description = "Internal ALB DNS name (use from bastion)"
  value       = module.alb.alb_dns_name
}
