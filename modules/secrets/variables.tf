variable "parameter_prefix" {
  description = "SSM Parameter Store path prefix including the leading slash."
  type        = string

  validation {
    condition     = startswith(var.parameter_prefix, "/") && !endswith(var.parameter_prefix, "/")
    error_message = "parameter_prefix must start with '/' and must not end with '/'."
  }
}

variable "ecs_secret_read_policy_name" {
  description = "Name of the IAM policy that allows ECS to read managed SSM parameters."
  type        = string
}

variable "postgres_password_version" {
  description = "Version used to trigger PostgreSQL password rotation."
  type        = number
  default     = 1

  validation {
    condition     = var.postgres_password_version > 0
    error_message = "postgres_password_version must be greater than zero."
  }
}

variable "redis_auth_token_version" {
  description = "Version used to trigger Redis AUTH token rotation."
  type        = number
  default     = 1

  validation {
    condition     = var.redis_auth_token_version > 0
    error_message = "redis_auth_token_version must be greater than zero."
  }
}

variable "additional_parameter_arns" {
  description = "Additional user-managed SSM parameter ARNs that ECS may read."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to the SSM parameters."
  type        = map(string)
  default     = {}
}
