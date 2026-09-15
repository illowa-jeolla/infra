locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "illowa-jeolla/infra"
  }
}

data "aws_caller_identity" "current" {}

module "network" {
  source = "../../modules/network"

  project                   = var.project
  environment               = var.environment
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  tags                      = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name               = "${local.name_prefix}-api"
  max_image_count               = var.ecr_max_image_count
  untagged_image_retention_days = var.ecr_untagged_image_retention_days
  tags                          = local.common_tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  project     = var.project
  environment = var.environment
  vpc_id      = module.network.vpc_id
  tags        = local.common_tags
}

module "s3_assets" {
  source = "../../modules/s3-assets"

  bucket_name            = "${local.name_prefix}-assets-${data.aws_caller_identity.current.account_id}"
  api_access_policy_name = "${local.name_prefix}-assets-access-policy"
  tags                   = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  parameter_prefix            = "/${var.project}/${var.environment}"
  ecs_secret_read_policy_name = "${local.name_prefix}-ecs-secrets-policy"
  postgres_password_version   = var.postgres_password_version
  redis_auth_token_version    = var.redis_auth_token_version
  tags                        = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  identifier              = "${local.name_prefix}-db"
  subnet_group_name       = "${local.name_prefix}-db-subnets"
  parameter_group_name    = "${local.name_prefix}-postgres"
  subnet_ids              = module.network.private_data_subnet_ids
  security_group_id       = module.security_groups.rds_security_group_id
  availability_zone       = var.availability_zones[0]
  engine_version          = var.postgres_engine_version
  instance_class          = var.postgres_instance_class
  allocated_storage       = var.postgres_allocated_storage
  database_name           = "illowajeolla"
  master_username         = "illowajeolla_admin"
  master_password         = module.secrets.postgres_password
  master_password_version = var.postgres_password_version
  tags                    = local.common_tags
}

module "redis" {
  source = "../../modules/redis"

  replication_group_id        = "${local.name_prefix}-redis"
  subnet_group_name           = "${local.name_prefix}-redis-subnets"
  parameter_group_name        = "${local.name_prefix}-redis"
  subnet_ids                  = module.network.private_data_subnet_ids
  security_group_id           = module.security_groups.redis_security_group_id
  preferred_availability_zone = var.availability_zones[0]
  engine_version              = var.redis_engine_version
  node_type                   = var.redis_node_type
  auth_token                  = module.secrets.redis_auth_token
  auth_token_version          = var.redis_auth_token_version
  tags                        = local.common_tags
}
