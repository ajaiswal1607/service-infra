aws_region   = "ap-south-1"
project_name = "enterprise-eks"
environment  = "dev"

vpc_cidr = "10.20.0.0/16"
az_count = 2

eks_version = "1.33"

node_instance_types = ["t3.large"]
node_min_size       = 2
node_desired_size   = 2
node_max_size       = 4

github_org  = "ajaiswal1607"
github_repo = "service-infra"
