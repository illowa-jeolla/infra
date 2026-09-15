output "state_bucket_name" {
  description = "S3 bucket to pass to the main environment backend configuration."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket."
  value       = aws_s3_bucket.terraform_state.arn
}

output "main_backend_configuration" {
  description = "Non-secret values required to initialize environments/main."
  value = {
    bucket       = aws_s3_bucket.terraform_state.id
    key          = "main/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}
