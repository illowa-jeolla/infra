variable "project" {
  description = "Project name used in security group names."
  type        = string
}

variable "environment" {
  description = "Environment name used in security group names."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups are created."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "IPv4 CIDR blocks allowed to access the public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.alb_ingress_cidrs) > 0
    error_message = "alb_ingress_cidrs must contain at least one IPv4 CIDR block."
  }
}

variable "tags" {
  description = "Additional tags applied to the security groups."
  type        = map(string)
  default     = {}
}
