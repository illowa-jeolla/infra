output "vpc_id" {
  description = "ID of the main VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets."
  value       = module.network.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "IDs of the isolated private data subnets."
  value       = module.network.private_data_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the shared NAT Gateway."
  value       = module.network.nat_gateway_id
}

output "ecr_repository_name" {
  description = "Name of the API ECR repository."
  value       = module.ecr.repository_name
}

output "ecr_repository_url" {
  description = "URL of the API ECR repository."
  value       = module.ecr.repository_url
}

output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = module.security_groups.alb_security_group_id
}

output "ecs_api_security_group_id" {
  description = "ID of the ECS API task security group."
  value       = module.security_groups.ecs_api_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = module.security_groups.rds_security_group_id
}

output "redis_security_group_id" {
  description = "ID of the Redis security group."
  value       = module.security_groups.redis_security_group_id
}

output "community_image_bucket_name" {
  description = "Name of the private community image bucket."
  value       = module.s3_assets.bucket_name
}

output "community_image_bucket_arn" {
  description = "ARN of the private community image bucket."
  value       = module.s3_assets.bucket_arn
}

output "community_image_api_access_policy_arn" {
  description = "ARN of the community image object access policy for the ECS API task role."
  value       = module.s3_assets.api_access_policy_arn
}

output "postgres_address" {
  description = "DNS address used by the API to connect to PostgreSQL."
  value       = module.rds.address
}

output "postgres_database_name" {
  description = "PostgreSQL database name used by the API."
  value       = module.rds.database_name
}

output "postgres_master_username" {
  description = "PostgreSQL master username used by the API."
  value       = module.rds.master_username
}

output "postgres_password_parameter_arn" {
  description = "ARN of the PostgreSQL password SSM parameter."
  value       = module.secrets.postgres_password_parameter_arn
}

output "ecs_secret_read_policy_arn" {
  description = "ARN of the SSM secret read policy for the ECS task execution role."
  value       = module.secrets.ecs_secret_read_policy_arn
}

output "redis_auth_token_parameter_arn" {
  description = "ARN of the Redis AUTH token SSM parameter."
  value       = module.secrets.redis_auth_token_parameter_arn
}

output "redis_port" {
  description = "Port used by the API to connect to Redis."
  value       = module.redis.port
}

output "redis_primary_endpoint_address" {
  description = "Primary DNS address used by the API to connect to Redis."
  value       = module.redis.primary_endpoint_address
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = module.alb.dns_name
}

output "api_certificate_arn" {
  description = "ARN of the ACM certificate currently attached to the ALB."
  value       = module.acm.certificate_arns[var.api_domain_name]
}

output "api_certificate_status" {
  description = "Status of the ACM certificate currently attached to the ALB."
  value       = module.acm.statuses[var.api_domain_name]
}

output "api_certificate_statuses" {
  description = "Statuses of all ACM certificates keyed by domain name."
  value       = module.acm.statuses
}

output "api_certificate_dns_validation_records" {
  description = "CNAME records to add at the external DNS provider for ACM validation."
  value       = module.acm.dns_validation_records
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the Application Load Balancer."
  value       = module.alb.zone_id
}

output "api_url" {
  description = "Public HTTPS URL of the backend API."
  value       = "https://${var.api_domain_name}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS API cluster."
  value       = module.ecs_api.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS API service."
  value       = module.ecs_api.service_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS API task definition revision."
  value       = module.ecs_api.task_definition_arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = module.ecs_api.execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS API application task role."
  value       = module.ecs_api.task_role_arn
}

output "api_log_group_name" {
  description = "CloudWatch log group for the API container."
  value       = module.ecs_api.log_group_name
}

output "github_oidc_provider_arn" {
  description = "ARN of the account-level GitHub Actions OIDC provider."
  value       = module.github_oidc.provider_arn
}

output "be_deploy_role_arn" {
  description = "IAM role ARN used by the backend GitHub Actions deployment workflow."
  value       = module.github_oidc.role_arn
}

output "be_deploy_policy_arn" {
  description = "IAM policy ARN attached to the backend deployment role."
  value       = module.github_oidc.policy_arn
}

output "be_deploy_trusted_subject" {
  description = "GitHub OIDC subject allowed to assume the backend deployment role."
  value       = module.github_oidc.trusted_subject
}
