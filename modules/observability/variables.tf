variable "asg_name" {
  description = "Name of the application Auto Scaling Group"
  type        = string
}

variable "bastion_instance_id" {
  description = "EC2 Instance ID of the bastion"
  type        = string
}

variable "alerts_email" {
  description = "Email address to subscribe to SNS alerts (confirm via email)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
