output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_kms_key_arn" {
  description = "KMS key ARN used to encrypt Terraform state."
  value       = aws_kms_key.terraform_state.arn
}

output "github_plan_role_arn" {
  description = "Role assumed by GitHub Actions for read-only Terraform plans."
  value       = aws_iam_role.github_plan.arn
}

output "github_apply_role_arn" {
  description = "Role assumed by GitHub Actions for environment-scoped Terraform applies."
  value       = aws_iam_role.github_apply.arn
}

output "aws_region" {
  description = "Bootstrap AWS region."
  value       = var.aws_region
}
