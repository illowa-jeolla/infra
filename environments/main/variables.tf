variable "aws_region" {
  description = "AWS region where main environment resources are created."
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Project name used for resource names and tags."
  type        = string
  default     = "illowa-jeolla"
}

variable "environment" {
  description = "Environment name used for resource names and tags."
  type        = string
  default     = "main"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the main environment."
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for the private application subnets."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for the isolated private data subnets."
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "ecr_max_image_count" {
  description = "Maximum number of images retained in ECR."
  type        = number
  default     = 30
}

variable "ecr_untagged_image_retention_days" {
  description = "Number of days to retain untagged ECR images."
  type        = number
  default     = 7
}

variable "postgres_engine_version" {
  description = "RDS PostgreSQL engine version."
  type        = string
  default     = "17.11"
}

variable "postgres_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "postgres_allocated_storage" {
  description = "RDS PostgreSQL gp3 storage in GiB."
  type        = number
  default     = 20
}

variable "postgres_password_version" {
  description = "Version used to trigger PostgreSQL password rotation."
  type        = number
  default     = 1
}

variable "redis_engine_version" {
  description = "ElastiCache Redis engine version."
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_auth_token_version" {
  description = "Version used to trigger Redis AUTH token rotation."
  type        = number
  default     = 1
}

variable "api_domain_name" {
  description = "Active public custom domain used by the backend API."
  type        = string
  default     = "api.illowa-jeolla.cloud"
}

variable "api_certificate_domain_names" {
  description = "API domains with independently managed ACM certificates during DNS migration."
  type        = set(string)
  default = [
    "api.cltrmp.cloud",
    "api.illowa-jeolla.cloud",
  ]

  validation {
    condition     = contains(var.api_certificate_domain_names, var.api_domain_name)
    error_message = "api_certificate_domain_names must include api_domain_name."
  }
}

variable "api_image_tag" {
  description = "Immutable ECR image tag deployed by the ECS API service."
  type        = string
  default     = "225fca632481"

  validation {
    condition     = length(trimspace(var.api_image_tag)) > 0 && var.api_image_tag != "latest"
    error_message = "api_image_tag must be a non-empty immutable tag and cannot be latest."
  }
}

variable "api_task_cpu" {
  description = "Fargate API task CPU units."
  type        = number
  default     = 512
}

variable "api_task_memory" {
  description = "Fargate API task memory in MiB."
  type        = number
  default     = 1024
}

variable "api_desired_count" {
  description = "API task count. Keep at zero until all production URLs and secrets are configured."
  type        = number
  default     = 0

  validation {
    condition     = var.api_desired_count >= 0 && var.api_desired_count <= 1
    error_message = "api_desired_count must be 0 or 1 while schedulers run inside the API process."
  }
}

variable "api_log_retention_days" {
  description = "CloudWatch retention period for API logs."
  type        = number
  default     = 14
}

variable "api_environment" {
  description = "Production-specific plain-text API environment variables merged with infrastructure values."
  type        = map(string)
  default     = {}
}

variable "api_secret_parameter_arns" {
  description = "Additional API secret environment variable names mapped to existing SSM parameter ARNs."
  type        = map(string)
  default     = {}
}

variable "api_required_environment_names" {
  description = "Environment variables required before the ECS API task count can exceed zero."
  type        = set(string)
  default = [
    "JWT_ACCESS_EXPIRATION",
    "JWT_REFRESH_EXPIRATION",
    "JWT_COOKIE_SECURE",
    "KAKAO_CLIENT_ID",
    "KAKAO_REDIRECT_URI",
    "GOOGLE_CLIENT_ID",
    "GOOGLE_REDIRECT_URI",
    "FRONTEND_OAUTH_CALLBACK_URI",
    "FRONTEND_ORIGIN",
  ]
}

variable "api_required_secret_names" {
  description = "SSM-backed secrets required before the ECS API task count can exceed zero."
  type        = set(string)
  default = [
    "POSTGRES_PASSWORD",
    "REDIS_PASSWORD",
    "JWT_SECRET",
    "KAKAO_CLIENT_SECRET",
    "GOOGLE_CLIENT_SECRET",
  ]
}
