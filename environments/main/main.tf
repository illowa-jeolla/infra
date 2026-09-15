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
