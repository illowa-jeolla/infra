output "provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "role_arn" {
  description = "ARN of the IAM role assumed by the backend deployment workflow."
  value       = aws_iam_role.backend_deploy.arn
}

output "policy_arn" {
  description = "ARN of the least-privilege backend deployment policy."
  value       = aws_iam_policy.backend_deploy.arn
}

output "trusted_subject" {
  description = "GitHub OIDC subject allowed to assume the deployment role."
  value       = local.github_subject
}
