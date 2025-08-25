variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "bastion_allowed_ssh_cidr" {
  description = "Your IP in CIDR to allow SSH to bastion (e.g., 203.0.113.45/32)"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

# variable "enable_temp_http_from_bastion" {
#   description = "TEMP: allow HTTP 80 from bastion directly to app instances for testing without ALB"
#   type        = bool
#   default     = false
# }