variable "name" {
  description = "Name of the Application Load Balancer."
  type        = string
}

variable "target_group_name" {
  description = "Name of the API target group."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing ALB."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two public subnets are required for an ALB."
  }
}

variable "security_group_id" {
  description = "Security group ID attached to the ALB."
  type        = string
}

variable "container_port" {
  description = "Port exposed by the API container."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP path used by the target group health check."
  type        = string
  default     = "/actuator/health/liveness"
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN. HTTP forwards directly when omitted and redirects to HTTPS when provided."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.certificate_arn == null || startswith(var.certificate_arn, "arn:aws:acm:")
    error_message = "certificate_arn must be null or an ACM certificate ARN."
  }
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection is enabled on the ALB."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to ALB resources."
  type        = map(string)
  default     = {}
}
