# Complete AWS EKS Infrastructure

Enterprise-ready baseline infrastructure for:
- VPC with public/private subnets
- NAT Gateway
- EKS cluster
- EC2 managed node group
- EKS addons
- EBS CSI
- Pod Identity Agent
- AWS Load Balancer Controller
- Metrics Server
- One common ECR repository for all services
- GitHub Actions OIDC roles
- CloudWatch EKS control-plane logging
- KMS encryption for EKS secrets
- Terraform remote-state bootstrap

## Structure

```text
complete-eks-infrastructure/
├── bootstrap-state/
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    ├── backend.tf.example
    ├── vpc.tf
    ├── eks.tf
    ├── ecr.tf
    ├── iam.tf
    ├── addons.tf
    └── terraform.tfvars.example
```

## Deployment order

1. Run `bootstrap-state` once to create the Terraform S3/DynamoDB backend.
2. Copy `backend.tf.example` to `backend.tf`.
3. Configure `terraform.tfvars`.
4. Run Terraform from `terraform/`.

## Common ECR

Only one ECR repository is created:

`enterprise-eks-dev`

Service images should use tags such as:

`order-service-<git-sha>`
`payment-service-<git-sha>`

## GitHub OIDC

Set:
- `github_org`
- `github_repo`

The application role is restricted to the repository's main branch.
