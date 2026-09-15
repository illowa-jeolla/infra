variable "domain_names" {
  description = "Fully qualified API domain names that each receive a separate certificate."
  type        = set(string)

  validation {
    condition = length(var.domain_names) > 0 && alltrue([
      for domain_name in var.domain_names :
      can(regex("^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$", domain_name))
    ])
    error_message = "domain_names must contain lowercase fully qualified domain names."
  }
}

variable "tags" {
  description = "Tags applied to the ACM certificate."
  type        = map(string)
  default     = {}
}
