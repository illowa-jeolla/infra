locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_security_group" "alb" {
  name                   = "${local.name_prefix}-alb-sg"
  description            = "Security group for the public Application Load Balancer"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "ecs_api" {
  name                   = "${local.name_prefix}-api-sg"
  description            = "Security group for ECS API tasks"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-api-sg"
  })
}

resource "aws_security_group" "rds" {
  name                   = "${local.name_prefix}-rds-sg"
  description            = "Security group for PostgreSQL RDS"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-sg"
  })
}

resource "aws_security_group" "redis" {
  name                   = "${local.name_prefix}-redis-sg"
  description            = "Security group for ElastiCache Redis"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow public HTTP 80 for HTTPS redirect"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow public HTTPS 443"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs_api" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ecs_api.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Allow ALB to API tasks on TCP 8080"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_api_from_alb" {
  security_group_id            = aws_security_group.ecs_api.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Allow ALB to API tasks on TCP 8080"
}

resource "aws_vpc_security_group_egress_rule" "ecs_api_all" {
  security_group_id = aws_security_group.ecs_api.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow API tasks to AWS services and external APIs"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs_api" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs_api.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow API tasks to PostgreSQL 5432"
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs_api" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.ecs_api.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Allow API tasks to Redis 6379"
}
