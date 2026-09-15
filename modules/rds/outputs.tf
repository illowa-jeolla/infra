output "address" {
  description = "DNS address of the PostgreSQL instance."
  value       = aws_db_instance.this.address
}

output "arn" {
  description = "ARN of the PostgreSQL instance."
  value       = aws_db_instance.this.arn
}

output "database_name" {
  description = "Name of the initial PostgreSQL database."
  value       = aws_db_instance.this.db_name
}

output "endpoint" {
  description = "Connection endpoint of the PostgreSQL instance."
  value       = aws_db_instance.this.endpoint
}

output "identifier" {
  description = "Identifier of the PostgreSQL instance."
  value       = aws_db_instance.this.identifier
}

output "master_username" {
  description = "Master username of the PostgreSQL instance."
  value       = aws_db_instance.this.username
}

output "port" {
  description = "Port of the PostgreSQL instance."
  value       = aws_db_instance.this.port
}
