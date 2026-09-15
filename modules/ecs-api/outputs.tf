output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Name of the ECS API service."
  value       = aws_ecs_service.api.name
}

output "task_definition_arn" {
  description = "ARN of the ECS API task definition revision."
  value       = aws_ecs_task_definition.api.arn
}

output "execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ARN of the API application task role."
  value       = aws_iam_role.task.arn
}

output "log_group_name" {
  description = "CloudWatch log group used by the API container."
  value       = aws_cloudwatch_log_group.api.name
}
