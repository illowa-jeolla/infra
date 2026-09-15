output "postgres_password" {
  description = "Ephemeral PostgreSQL password read from SSM Parameter Store."
  value       = ephemeral.aws_ssm_parameter.postgres_password.value
  sensitive   = true
  ephemeral   = true
}

output "ecs_secret_read_policy_arn" {
  description = "ARN of the IAM policy to attach to the ECS task execution role."
  value       = aws_iam_policy.ecs_secret_read.arn
}

output "postgres_password_parameter_arn" {
  description = "ARN of the PostgreSQL password SSM parameter."
  value       = aws_ssm_parameter.postgres_password.arn
}

output "postgres_password_parameter_name" {
  description = "Name of the PostgreSQL password SSM parameter."
  value       = aws_ssm_parameter.postgres_password.name
}

output "redis_auth_token" {
  description = "Ephemeral Redis AUTH token read from SSM Parameter Store."
  value       = ephemeral.aws_ssm_parameter.redis_auth_token.value
  sensitive   = true
  ephemeral   = true
}

output "redis_auth_token_parameter_arn" {
  description = "ARN of the Redis AUTH token SSM parameter."
  value       = aws_ssm_parameter.redis_auth_token.arn
}

output "redis_auth_token_parameter_name" {
  description = "Name of the Redis AUTH token SSM parameter."
  value       = aws_ssm_parameter.redis_auth_token.name
}
