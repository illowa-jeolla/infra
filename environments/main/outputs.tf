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
