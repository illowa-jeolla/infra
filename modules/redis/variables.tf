variable "replication_group_id" {
  description = "Identifier of the ElastiCache Redis replication group."
  type        = string
}

variable "subnet_group_name" {
  description = "Name of the ElastiCache subnet group."
  type        = string
}

variable "parameter_group_name" {
  description = "Name of the ElastiCache Redis parameter group."
  type        = string
}

variable "subnet_ids" {
  description = "Private data subnet IDs used by ElastiCache."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least two subnets."
  }
}

variable "security_group_id" {
  description = "Security group ID attached to the Redis replication group."
  type        = string
}

variable "preferred_availability_zone" {
  description = "Availability zone for the single Redis node."
  type        = string
}

variable "engine_version" {
  description = "ElastiCache Redis engine version."
  type        = string
  default     = "7.1"
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "auth_token" {
  description = "Ephemeral Redis AUTH token."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "auth_token_version" {
  description = "Version used to trigger Redis AUTH token rotation."
  type        = number
}

variable "snapshot_retention_days" {
  description = "Number of days to retain automatic Redis snapshots."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Additional tags applied to ElastiCache resources."
  type        = map(string)
  default     = {}
}
