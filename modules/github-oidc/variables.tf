variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
}

variable "policy_name" {
  description = "Name of the IAM policy used by the backend deployment workflow."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the role, in owner/repository form."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must use the owner/repository form."
  }
}

variable "github_repository_owner_id" {
  description = "Immutable GitHub organization or user ID included in the customized OIDC subject."
  type        = string
}

variable "github_repository_id" {
  description = "Immutable GitHub repository ID included in the customized OIDC subject."
  type        = string
}

variable "github_ref" {
  description = "Full Git ref allowed to assume the role."
  type        = string

  validation {
    condition     = startswith(var.github_ref, "refs/")
    error_message = "github_ref must be a full ref such as refs/heads/main."
  }
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository to which the workflow can push images."
  type        = string
}

variable "ecs_service_arn" {
  description = "ARN of the ECS service that the workflow can update."
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role the workflow can pass to ECS."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS application task role the workflow can pass to ECS."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to taggable resources."
  type        = map(string)
  default     = {}
}
