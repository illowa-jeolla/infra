output "arn" {
  description = "ARN of the Redis replication group."
  value       = aws_elasticache_replication_group.this.arn
}

output "engine_version_actual" {
  description = "Actual Redis engine version selected by ElastiCache."
  value       = aws_elasticache_replication_group.this.engine_version_actual
}

output "port" {
  description = "Port of the Redis replication group."
  value       = aws_elasticache_replication_group.this.port
}

output "primary_endpoint_address" {
  description = "Primary DNS endpoint of the Redis replication group."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "replication_group_id" {
  description = "Identifier of the Redis replication group."
  value       = aws_elasticache_replication_group.this.replication_group_id
}
