variable "vpc_id" {
  description = "ID of the VPC to place subnets and gateways into"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create: name -> { cidr, az, public }"
  type = map(object({
    cidr   = string
    az     = string
    public = bool
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
