resource "kubernetes_namespace" "chromadb" {

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_persistent_volume_claim" "chromadb" {

  metadata {
    name      = "chromadb-pvc"
    namespace = kubernetes_namespace.chromadb.metadata[0].name
  }

  spec {

    access_modes = [
      "ReadWriteOnce"
    ]

    storage_class_name = "gp3"

    resources {

      requests = {
        storage = var.storage_size
      }
    }
  }
}
resource "kubernetes_deployment" "chromadb" {

  metadata {
    name      = "chromadb"
    namespace = kubernetes_namespace.chromadb.metadata[0].name

    labels = {
      app = "chromadb"
    }
  }

  spec {

    replicas = 1

    selector {

      match_labels = {
        app = "chromadb"
      }
    }

    template {

      metadata {

        labels = {
          app = "chromadb"
        }
      }

      spec {

        container {

          name = "chromadb"

          image = var.image

          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8000
          }

          #
          # ChromaDB persistence
          #

          env {
            name  = "IS_PERSISTENT"
            value = "TRUE"
          }

          env {
            name  = "PERSIST_DIRECTORY"
            value = "/data"
          }

          #
          # Resources
          #

          resources {

            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }

            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
          }

          #
          # Persistent storage
          #

          volume_mount {

            name = "chromadb-data"

            mount_path = "/data"
          }

          #
          # Readiness probe
          #

          readiness_probe {

            http_get {

              path = "/api/v2/heartbeat"

              port = 8000
            }

            initial_delay_seconds = 10

            period_seconds = 10

            timeout_seconds = 5

            failure_threshold = 6
          }

          #
          # Liveness probe
          #

          liveness_probe {

            http_get {

              path = "/api/v2/heartbeat"

              port = 8000
            }

            initial_delay_seconds = 30

            period_seconds = 20

            timeout_seconds = 5

            failure_threshold = 6
          }
        }

        #
        # Mount PVC
        #

        volume {

          name = "chromadb-data"

          persistent_volume_claim {

            claim_name =
            kubernetes_persistent_volume_claim.chromadb.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "chromadb" {

  metadata {

    name = "chromadb"

    namespace =
    kubernetes_namespace.chromadb.metadata[0].name
  }

  spec {

    type = "ClusterIP"

    selector = {

      app = "chromadb"
    }

    port {

      name = "http"

      port = 8000

      target_port = 8000

      protocol = "TCP"
    }
  }
}