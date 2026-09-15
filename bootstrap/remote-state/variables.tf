variable "aws_region" {
  description = "AWS region that stores the Terraform state bucket."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name used in the generated bucket name."
  type        = string
  default     = "illowa-jeolla"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "state_bucket_name" {
  description = "Optional explicit globally unique state bucket name. Null generates <project>-tfstate-<account-id>."
  type        = string
  default     = null

  validation {
    condition = var.state_bucket_name == null || can(regex(
      "^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$",
      var.state_bucket_name
    ))
    error_message = "state_bucket_name must be null or a valid 3-63 character S3 bucket name."
  }
}

variable "common_tags" {
  description = "Tags applied to all bootstrap resources."
  type        = map(string)
  default = {
    Project     = "illowa-jeolla"
    Environment = "shared"
    ManagedBy   = "terraform"
    Repository  = "illowa-jeolla/infra"
  }
}
