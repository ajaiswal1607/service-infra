output "terraform_role_arn" {
  description = "IAM role ARN used by GitHub Actions for Terraform"
  value       = aws_iam_role.github_terraform.arn
}

output "terraform_role_name" {
  description = "IAM role name used by GitHub Actions for Terraform"
  value       = aws_iam_role.github_terraform.name
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "terraform_state_bucket" {
  description = "Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}