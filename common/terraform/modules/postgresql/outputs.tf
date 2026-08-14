output "namespace" {

  value = kubernetes_namespace.postgresql.metadata[0].name
}

output "service_name" {

  value = kubernetes_service.postgresql.metadata[0].name
}

output "host" {

  value = "postgresql.${var.namespace}.svc.cluster.local"
}

output "port" {

  value = 5432
}

output "database" {

  value = var.database
}

output "username" {

  value = var.username
}