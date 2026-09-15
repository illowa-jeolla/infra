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
