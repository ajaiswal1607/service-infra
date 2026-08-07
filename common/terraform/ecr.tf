resource "aws_ecr_repository" "services" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "services" {
  repository = aws_ecr_repository.services.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep latest 100 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 100
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_iam_policy" "github_ecr" {
  name = "${var.project_name}-${var.environment}-github-ecr"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = aws_ecr_repository.services.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr" {
  role       = aws_iam_role.github_application.name
  policy_arn = aws_iam_policy.github_ecr.arn
}

resource "aws_iam_policy" "github_eks_describe" {
  name = "${var.project_name}-${var.environment}-github-eks-describe"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["eks:DescribeCluster"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_eks_describe" {
  role       = aws_iam_role.github_application.name
  policy_arn = aws_iam_policy.github_eks_describe.arn
}
