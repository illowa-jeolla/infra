locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "illowa-jeolla/infra"
  }

  api_environment = merge(
    {
      SPRING_PROFILES_ACTIVE                 = "prod"
      POSTGRES_HOST                          = module.rds.address
      POSTGRES_PORT                          = "5432"
      POSTGRES_DB                            = module.rds.database_name
      POSTGRES_USER                          = module.rds.master_username
      REDIS_HOST                             = module.redis.primary_endpoint_address
      REDIS_PORT                             = tostring(module.redis.port)
      REDIS_SSL                              = "true"
      JPA_DDL_AUTO                           = "update"
      SPRING_BATCH_JDBC_INITIALIZE_SCHEMA    = "always"
      COMMUNITY_IMAGE_STORAGE                = "s3"
      COMMUNITY_IMAGE_S3_BUCKET              = module.s3_assets.bucket_name
      COMMUNITY_IMAGE_URL_EXPIRATION_MINUTES = "30"
      AWS_REGION                             = var.aws_region
    },
    var.api_environment,
  )

  api_secrets = merge(
    {
      POSTGRES_PASSWORD = module.secrets.postgres_password_parameter_arn
      REDIS_PASSWORD    = module.secrets.redis_auth_token_parameter_arn
    },
    var.api_secret_parameter_arns,
  )
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
  additional_parameter_arns   = toset(values(var.api_secret_parameter_arns))
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

module "acm" {
  source = "../../modules/acm"

  domain_names = var.api_certificate_domain_names
  tags         = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name                       = "${local.name_prefix}-alb"
  target_group_name          = "${local.name_prefix}-api-tg"
  vpc_id                     = module.network.vpc_id
  public_subnet_ids          = module.network.public_subnet_ids
  security_group_id          = module.security_groups.alb_security_group_id
  container_port             = 8080
  health_check_path          = "/actuator/health/liveness"
  certificate_arn            = module.acm.certificate_arns[var.api_domain_name]
  enable_deletion_protection = false
  tags                       = local.common_tags
}

module "ecs_api" {
  source = "../../modules/ecs-api"

  cluster_name       = "${local.name_prefix}-cluster"
  service_name       = "${local.name_prefix}-api-svc"
  task_family        = "${local.name_prefix}-api"
  container_name     = "api"
  container_image    = "${module.ecr.repository_url}:${var.api_image_tag}"
  container_port     = 8080
  task_cpu           = var.api_task_cpu
  task_memory        = var.api_task_memory
  desired_count      = var.api_desired_count
  private_subnet_ids = module.network.private_app_subnet_ids
  security_group_id  = module.security_groups.ecs_api_security_group_id
  target_group_arn   = module.alb.target_group_arn

  execution_role_name               = "${local.name_prefix}-ecs-execution-role"
  task_role_name                    = "${local.name_prefix}-api-task-role"
  execution_secret_policy_arn       = module.secrets.ecs_secret_read_policy_arn
  task_role_policy_arns             = [module.s3_assets.api_access_policy_arn]
  log_group_name                    = "/ecs/${var.project}/${var.environment}/api"
  log_retention_days                = var.api_log_retention_days
  aws_region                        = var.aws_region
  environment                       = local.api_environment
  secrets                           = local.api_secrets
  required_environment_names        = var.api_required_environment_names
  required_secret_names             = var.api_required_secret_names
  health_check_grace_period_seconds = 180
  tags                              = local.common_tags

}
