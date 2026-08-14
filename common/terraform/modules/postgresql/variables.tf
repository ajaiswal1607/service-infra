variable "namespace" {
  type        = string
  description = "PostgreSQL namespace"
}

variable "image" {
  type        = string
  description = "PostgreSQL Docker image"
  default     = "postgres:16"
}

variable "storage_size" {
  type        = string
  description = "PostgreSQL persistent storage"
  default     = "5Gi"
}

variable "database" {
  type        = string
  default     = "appdb"
}

variable "username" {
  type        = string
  default     = "appuser"
}

variable "password" {
  type        = string
  sensitive   = true
}