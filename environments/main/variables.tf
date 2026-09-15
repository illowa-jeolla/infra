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
