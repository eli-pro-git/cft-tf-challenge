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

  # Updated to six subnets (2x Management, 2x Application, 2x Backend)
  default = {
    # Public (Management)
    management_a = {
      cidr   = "10.1.77.0/24"   # new
      az     = "us-east-1a"
      public = true
    }
    management_b = {
      cidr   = "10.1.78.0/24"   # original
      az     = "us-east-1b"
      public = true
    }

    # Private (Application)
    application_a = {
      cidr   = "10.1.10.0/24"   # new
      az     = "us-east-1a"
      public = false
    }
    application_b = {
      cidr   = "10.1.9.0/24"    # original
      az     = "us-east-1b"
      public = false
    }

    # Private (Backend)
    backend_a = {
      cidr   = "10.1.21.0/24"   # original
      az     = "us-east-1a"
      public = false
    }
    backend_b = {
      cidr   = "10.1.22.0/24"   # new
      az     = "us-east-1b"
      public = false
    }
  }
}



# Your public IP for SSH to the bastion, in CIDR /32 form.
# Replace with something like "203.0.113.45/32"
variable "bastion_allowed_ssh_cidr" {
  description = "Your IP in CIDR to allow SSH to bastion (e.g., 203.0.113.45/32)"
  type        = string
  default     = "your_ip-here/32"
}

# The name of an existing EC2 Key Pair in the chosen region.
# Create one in AWS Console (EC2 → Key Pairs) or via CLI, then put its name here.
variable "bastion_key_name" {
  description = "cfc-key-pair.pem"
  type        = string
}

variable "alerts_email" {
  description = "Email to receive CloudWatch alerts (leave empty to skip email subscription)"
  type        = string
  default     = ""
}
