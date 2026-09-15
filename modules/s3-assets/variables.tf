variable "bucket_name" {
  description = "Globally unique name of the private asset bucket."
  type        = string
}

variable "api_access_policy_name" {
  description = "Name of the IAM policy that grants API tasks object access."
  type        = string
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days to retain noncurrent object versions."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_expiration_days > 0
    error_message = "noncurrent_version_expiration_days must be greater than zero."
  }
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Number of days before incomplete multipart uploads are aborted."
  type        = number
  default     = 7

  validation {
    condition     = var.abort_incomplete_multipart_upload_days > 0
    error_message = "abort_incomplete_multipart_upload_days must be greater than zero."
  }
}

variable "tags" {
  description = "Additional tags applied to taggable resources."
  type        = map(string)
  default     = {}
}
