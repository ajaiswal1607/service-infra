# Terraform backend

`backend.tf` intentionally contains only:

```hcl
terraform {
  backend "s3" {
    use_lockfile = true
  }
}
```

The actual bucket/key/region are supplied by GitHub Actions using `-backend-config`.

Required GitHub repository variables:

- `AWS_REGION`
- `TF_STATE_BUCKET`
- `TF_STATE_KEY`
- `TERRAFORM_ROLE_ARN`

Example:

```text
AWS_REGION=ap-south-1
TF_STATE_BUCKET=enterprise-eks-terraform-state
TF_STATE_KEY=dev/terraform.tfstate
```

Initialize locally:

```bash
terraform init   -backend-config="bucket=enterprise-eks-terraform-state"   -backend-config="key=dev/terraform.tfstate"   -backend-config="region=ap-south-1"   -backend-config="use_lockfile=true"
```

The state bucket must be created first by `bootstrap-state`.
