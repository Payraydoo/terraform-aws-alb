variable "tag_org" {
  description = "Organization tag"
  type        = string
}

variable "env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "security_groups" {
  description = "List of security group IDs to assign to the ALB"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnet IDs where ALB will be created"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate to use for HTTPS listeners"
  type        = string
}

variable "target_groups" {
  description = "List of target group configurations"
  type        = list(any)
  default     = []
}

variable "http_tcp_listeners" {
  description = "List of HTTP/TCP listener configurations"
  type        = list(any)
  default     = []
}

variable "https_listeners" {
  description = "List of HTTPS listener configurations"
  type        = list(any)
  default     = []
}

variable "idle_timeout" {
  description = "Idle timeout for connections in seconds"
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Whether to enable access logs"
  type        = bool
  default     = true
}

variable "access_logs_bucket" {
  description = "S3 bucket name to store access logs"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 bucket prefix to store access logs"
  type        = string
  default     = "alb-logs"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}