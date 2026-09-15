output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "ecs_api_security_group_id" {
  description = "ID of the ECS API task security group."
  value       = aws_security_group.ecs_api.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "ID of the Redis security group."
  value       = aws_security_group.redis.id
}
