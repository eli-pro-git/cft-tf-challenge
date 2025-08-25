# REPLACE the old 'subnet_id' variable with this:
variable "subnet_ids" {
  description = "Application subnet IDs (private) where ASG instances run (multi-AZ)"
  type        = list(string)
}


variable "security_group_id" {
  description = "App instance security group ID"
  type        = string
}

variable "key_name" {
  description = "EC2 keypair name (so you can SSH from bastion)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for app servers"
  type        = string
  default     = "t2.micro"
}

variable "asg_min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 6
}

variable "target_group_arn" {
  description = "ALB target group ARN to attach the ASG to"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "instance_profile_name" {
  description = "IAM instance profile name for SSM"
  type        = string
}
