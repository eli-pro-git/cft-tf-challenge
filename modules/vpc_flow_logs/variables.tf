variable "vpc_id" {
  description = "VPC ID to enable flow logs on"
  type        = string
}

variable "log_retention_days" {
  description = "Retention period for the CloudWatch Log Group"
  type        = number
  default     = 30
}

variable "traffic_type" {
  description = "ACCEPT | REJECT | ALL"
  type        = string
  default     = "ALL"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
