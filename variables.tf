variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}
# Default region per your spec; change if needed.
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

# Your VPC CIDR per requirements.
variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

# Simple, consistent tags (helpful for cost/DR tracking).
variable "project" {
  description = "Project tag"
  type        = string
  default     = "cpmc"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}


# Subnet definitions: name -> { cidr, az, public }
# We keep this as a map for easy reuse and future extension.
variable "subnets" {
  description = "Subnets to create"
  type = map(object({
    cidr   = string
    az     = string
    public = bool
  }))

  # Per your requirements:
  default = {
    management = {
      cidr   = "10.1.78.0/24"
      az     = "us-east-1b"
      public = true      # Internet accessible
    }
    application = {
      cidr   = "10.1.9.0/24"
      az     = "us-east-1b"
      public = false     # Private
    }
    backend = {
      cidr   = "10.1.21.0/24"
      az     = "us-east-1a"
      public = false     # Private
    }
  }
}

# Your public IP for SSH to the bastion, in CIDR /32 form.
# Replace with something like "203.0.113.45/32"
variable "bastion_allowed_ssh_cidr" {
  description = "Your IP in CIDR to allow SSH to bastion (e.g., 203.0.113.45/32)"
  type        = string
  default     = "71.121.144.119/32"
}

# The name of an existing EC2 Key Pair in the chosen region.
# Create one in AWS Console (EC2 → Key Pairs) or via CLI, then put its name here.
variable "bastion_key_name" {
  description = "cfc-key-pair.pem"
  type        = string
}
