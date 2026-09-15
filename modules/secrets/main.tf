ephemeral "random_password" "postgres" {
  length      = 32
  special     = false
  min_lower   = 8
  min_numeric = 4
  min_upper   = 8
}

ephemeral "random_password" "redis" {
  length      = 32
  special     = false
  min_lower   = 8
  min_numeric = 4
  min_upper   = 8
}

resource "aws_ssm_parameter" "postgres_password" {
  name        = "${var.parameter_prefix}/db/password"
  description = "Master password for the main PostgreSQL database"
  type        = "SecureString"
  tier        = "Standard"
  key_id      = "alias/aws/ssm"

  value_wo         = ephemeral.random_password.postgres.result
  value_wo_version = var.postgres_password_version

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

resource "aws_ssm_parameter" "redis_auth_token" {
  name        = "${var.parameter_prefix}/redis/password"
  description = "AUTH token for the main ElastiCache Redis replication group"
  type        = "SecureString"
  tier        = "Standard"
  key_id      = "alias/aws/ssm"

  value_wo         = ephemeral.random_password.redis.result
  value_wo_version = var.redis_auth_token_version

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

data "aws_iam_policy_document" "ecs_secret_read" {
  statement {
    sid    = "AllowEcsSecretParameterRead"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.postgres_password.arn,
      aws_ssm_parameter.redis_auth_token.arn,
    ]
  }
}

resource "aws_iam_policy" "ecs_secret_read" {
  name        = var.ecs_secret_read_policy_name
  description = "Allows the ECS task execution role to read application secrets from SSM"
  policy      = data.aws_iam_policy_document.ecs_secret_read.json

  tags = var.tags
}

ephemeral "aws_ssm_parameter" "postgres_password" {
  arn             = aws_ssm_parameter.postgres_password.arn
  with_decryption = true
}

ephemeral "aws_ssm_parameter" "redis_auth_token" {
  arn             = aws_ssm_parameter.redis_auth_token.arn
  with_decryption = true
}
