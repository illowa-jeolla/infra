variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS API service."
  type        = string
}

variable "task_family" {
  description = "ECS task definition family."
  type        = string
}

variable "container_name" {
  description = "Name of the API container."
  type        = string
  default     = "api"
}

variable "container_image" {
  description = "Immutable ECR image URI including a tag."
  type        = string

  validation {
    condition     = !endswith(var.container_image, ":latest")
    error_message = "container_image must use an immutable tag instead of latest."
  }
}

variable "container_port" {
  description = "Port exposed by the API container."
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of API tasks. Keep at zero until all production configuration is ready."
  type        = number
  default     = 0

  validation {
    condition     = var.desired_count >= 0 && var.desired_count <= 1
    error_message = "desired_count must be 0 or 1 while schedulers run inside the API process."
  }
}

variable "private_subnet_ids" {
  description = "Private application subnet IDs for ECS tasks."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private application subnets are required."
  }
}

variable "security_group_id" {
  description = "Security group ID attached to ECS tasks."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group."
  type        = string
}

variable "execution_role_name" {
  description = "Name of the ECS task execution role."
  type        = string
}

variable "task_role_name" {
  description = "Name of the application task role."
  type        = string
}

variable "execution_secret_policy_arn" {
  description = "IAM policy ARN allowing ECS to read task definition secrets."
  type        = string
}

variable "task_role_policy_arns" {
  description = "IAM policy ARNs attached to the application task role."
  type        = set(string)
  default     = []
}

variable "log_group_name" {
  description = "CloudWatch Logs log group name."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days."
  type        = number
  default     = 14
}

variable "aws_region" {
  description = "AWS region used by the awslogs driver."
  type        = string
}

variable "environment" {
  description = "Plain-text environment variables passed to the API container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Environment variable names mapped to SSM parameter ARNs."
  type        = map(string)
  default     = {}
}

variable "required_environment_names" {
  description = "Environment variables that must be non-empty before desired_count can exceed zero."
  type        = set(string)
  default     = []
}

variable "required_secret_names" {
  description = "Secret environment variables that must exist before desired_count can exceed zero."
  type        = set(string)
  default     = []
}

variable "health_check_grace_period_seconds" {
  description = "Grace period for ALB health checks during ECS deployment."
  type        = number
  default     = 180
}

variable "tags" {
  description = "Tags applied to ECS resources."
  type        = map(string)
  default     = {}
}
