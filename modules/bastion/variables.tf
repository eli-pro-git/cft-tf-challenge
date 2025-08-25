variable "subnet_id" {
  description = "Public (management) subnet ID for the bastion"
  type        = string
}

variable "sg_id" {
  description = "Security group ID to attach to the bastion"
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH"
  type        = string
}

variable "instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t2.micro"
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
