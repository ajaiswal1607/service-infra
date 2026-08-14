variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "anand-app"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "eks_version" {
  type    = string
  default = "1.33"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "eks_cluster_name" {
  type = string
  default = ""
}

variable "chromadb_namespace" {
  description = "Kubernetes namespace for ChromaDB"
  type        = string
  default     = "chromadb"
}

variable "chromadb_image" {
  description = "ChromaDB container image"
  type        = string
  default     = "chromadb/chroma:latest"
}

variable "storage_size" {
  description = "ChromaDB persistent storage"
  type        = string
  default     = "5Gi"
}
variable "postgresql_namespace" {

  type    = string
  default = "postgresql"
}

variable "postgresql_image" {

  type    = string
  default = "postgres:16"
}

variable "postgresql_storage_size" {

  type    = string
  default = "5Gi"
}

variable "postgresql_database" {

  type    = string
  default = "appdb"
}

variable "postgresql_username" {

  type    = string
  default = "appuser"
}

variable "postgresql_password" {

  type      = string
  sensitive = true
}