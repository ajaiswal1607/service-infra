provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

#
# Existing EKS cluster
#

data "aws_eks_cluster" "existing" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "existing" {
  name = var.eks_cluster_name
}

#
# Kubernetes provider
#

provider "kubernetes" {
  host = data.aws_eks_cluster.existing.endpoint

  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.existing.certificate_authority[0].data
  )

  token = data.aws_eks_cluster_auth.existing.token
}
