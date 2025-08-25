variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support for VPC"
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "VPC instance tenancy (default or dedicated)"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
