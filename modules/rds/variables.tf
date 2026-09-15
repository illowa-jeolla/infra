variable "identifier" {
  description = "Identifier of the RDS PostgreSQL instance."
  type        = string
}

variable "subnet_group_name" {
  description = "Name of the RDS DB subnet group."
  type        = string
}

variable "parameter_group_name" {
  description = "Name of the RDS PostgreSQL parameter group."
  type        = string
}

variable "subnet_ids" {
  description = "Private data subnet IDs used by the DB subnet group."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least two subnets."
  }
}

variable "security_group_id" {
  description = "Security group ID attached to the RDS instance."
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the Single-AZ RDS instance."
  type        = string
}

variable "engine_version" {
  description = "RDS PostgreSQL engine version."
  type        = string
  default     = "17.11"
}

variable "instance_class" {
  description = "RDS DB instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated gp3 storage in GiB."
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "illowajeolla"
}

variable "master_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "illowajeolla_admin"
}

variable "master_password" {
  description = "Ephemeral PostgreSQL master password."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "master_password_version" {
  description = "Version used to trigger PostgreSQL password rotation."
  type        = number
}

variable "backup_retention_days" {
  description = "Number of days to retain automated RDS backups."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags applied to RDS resources."
  type        = map(string)
  default     = {}
}
