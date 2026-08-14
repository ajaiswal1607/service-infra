output "namespace" {

  description = "ChromaDB namespace"

  value = kubernetes_namespace.chromadb.metadata[0].name
}


output "service_name" {

  description = "ChromaDB Kubernetes service"

  value = kubernetes_service.chromadb.metadata[0].name
}


output "internal_url" {

  description = "Internal ChromaDB URL"

  value = "http://chromadb.${var.namespace}.svc.cluster.local:8000"
}