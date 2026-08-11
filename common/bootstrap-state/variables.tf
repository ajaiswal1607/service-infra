variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "anand-app"
}

variable "github_org" {
  default = "ajaiswal1607"
}

variable "github_repo" {
  default = "service-infra"
}

variable "environment" {
  default = "dev"
}