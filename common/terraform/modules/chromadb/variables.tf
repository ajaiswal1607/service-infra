variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "image" {
  description = "ChromaDB Docker image"
  type        = string
}

variable "storage_size" {
  description = "Persistent volume size"
  type        = string
}