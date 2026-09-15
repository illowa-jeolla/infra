output "bucket_arn" {
  description = "ARN of the private asset bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_name" {
  description = "Name of the private asset bucket."
  value       = aws_s3_bucket.this.id
}

output "api_access_policy_arn" {
  description = "ARN of the IAM policy to attach to the ECS API task role."
  value       = aws_iam_policy.api_object_access.arn
}
