resource "aws_elasticache_subnet_group" "this" {
  name        = var.subnet_group_name
  description = "Private data subnets for ${var.replication_group_id}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = var.subnet_group_name
  })
}

resource "aws_elasticache_parameter_group" "this" {
  name        = var.parameter_group_name
  description = "Redis 7 parameters for ${var.replication_group_id}"
  family      = "redis7"

  tags = merge(var.tags, {
    Name = var.parameter_group_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = var.replication_group_id
  description          = "Single-node Redis for the main API"

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = 6379

  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  subnet_group_name           = aws_elasticache_subnet_group.this.name
  security_group_ids          = [var.security_group_id]
  preferred_cache_cluster_azs = [var.preferred_availability_zone]
  parameter_group_name        = aws_elasticache_parameter_group.this.name

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"

  auth_token_wo              = var.auth_token
  auth_token_wo_version      = var.auth_token_version
  auth_token_update_strategy = "SET"

  snapshot_retention_limit = var.snapshot_retention_days
  snapshot_window          = "20:00-21:00"
  maintenance_window       = "sun:22:00-sun:23:00"

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = merge(var.tags, {
    Name = var.replication_group_id
  })
}
