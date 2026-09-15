variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "max_image_count" {
  description = "Maximum number of images retained in the repository."
  type        = number
  default     = 30

  validation {
    condition     = var.max_image_count > 0
    error_message = "max_image_count must be greater than zero."
  }
}

variable "untagged_image_retention_days" {
  description = "Number of days to retain untagged images."
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_image_retention_days > 0
    error_message = "untagged_image_retention_days must be greater than zero."
  }
}

variable "tags" {
  description = "Additional tags applied to taggable resources."
  type        = map(string)
  default     = {}
}
