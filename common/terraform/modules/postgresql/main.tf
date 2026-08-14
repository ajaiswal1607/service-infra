resource "kubernetes_namespace" "postgresql" {

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "postgresql" {

  metadata {
    name      = "postgresql-secret"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
  }

  type = "Opaque"

  data = {
    POSTGRES_DB       = var.database
    POSTGRES_USER     = var.username
    POSTGRES_PASSWORD = var.password
  }
}

resource "kubernetes_persistent_volume_claim" "postgresql" {

  metadata {
    name      = "postgresql-pvc"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
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

resource "kubernetes_persistent_volume_claim" "postgresql" {

  metadata {
    name      = "postgresql-pvc"
    namespace = kubernetes_namespace.postgresql.metadata[0].name
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

resource "kubernetes_deployment" "postgresql" {

  metadata {

    name = "postgresql"

    namespace =
    kubernetes_namespace.postgresql.metadata[0].name

    labels = {
      app = "postgresql"
    }
  }

  spec {

    replicas = 1

    selector {

      match_labels = {
        app = "postgresql"
      }
    }

    template {

      metadata {

        labels = {
          app = "postgresql"
        }
      }

      spec {

        container {

          name = "postgresql"

          image = var.image

          port {

            name = "postgres"

            container_port = 5432
          }

          env {

            name = "POSTGRES_DB"

            value_from {

              secret_key_ref {

                name =
                kubernetes_secret.postgresql.metadata[0].name

                key = "POSTGRES_DB"
              }
            }
          }

          env {

            name = "POSTGRES_USER"

            value_from {

              secret_key_ref {

                name =
                kubernetes_secret.postgresql.metadata[0].name

                key = "POSTGRES_USER"
              }
            }
          }

          env {

            name = "POSTGRES_PASSWORD"

            value_from {

              secret_key_ref {

                name =
                kubernetes_secret.postgresql.metadata[0].name

                key = "POSTGRES_PASSWORD"
              }
            }
          }

          resources {

            requests = {

              cpu = "100m"

              memory = "256Mi"
            }

            limits = {

              cpu = "500m"

              memory = "512Mi"
            }
          }

          volume_mount {

            name = "postgresql-data"

            mount_path = "/var/lib/postgresql/data"
          }

          readiness_probe {

            exec {

              command = [
                "sh",
                "-c",
                "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"
              ]
            }

            initial_delay_seconds = 10

            period_seconds = 10
          }

          liveness_probe {

            exec {

              command = [
                "sh",
                "-c",
                "pg_isready -U $POSTGRES_USER -d $POSTGRES_DB"
              ]
            }

            initial_delay_seconds = 30

            period_seconds = 20
          }
        }

        volume {

          name = "postgresql-data"

          persistent_volume_claim {

            claim_name =
            kubernetes_persistent_volume_claim.postgresql.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgresql" {

  metadata {

    name = "postgresql"

    namespace =
    kubernetes_namespace.postgresql.metadata[0].name
  }

  spec {

    type = "ClusterIP"

    selector = {

      app = "postgresql"
    }

    port {

      name = "postgres"

      port = 5432

      target_port = 5432

      protocol = "TCP"
    }
  }
}