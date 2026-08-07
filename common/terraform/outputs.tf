output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.services.repository_url
}

output "github_application_role_arn" {
  value = aws_iam_role.github_application.arn
}

output "github_terraform_role_arn" {
  value = aws_iam_role.github_terraform.arn
}

output "vpc_id" {
  value = aws_vpc.main.id
}
