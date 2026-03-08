###############################################################################
# MongoDB — headless Service + StatefulSet
# Only deployed when using in-cluster MongoDB (mongo_host == "mongodb")
###############################################################################

locals {
  deploy_mongodb = var.mongo_host == "mongodb"
}

resource "kubernetes_service_v1" "mongodb" {
  count = local.deploy_mongodb ? 1 : 0

  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = merge(local.labels, { app = "mongodb" })
  }

  spec {
    selector   = { app = "mongodb" }
    cluster_ip = "None" # Headless — required for StatefulSet DNS

    port {
      port        = 27017
      target_port = 27017
    }
  }
}

resource "kubernetes_stateful_set_v1" "mongodb" {
  count = local.deploy_mongodb ? 1 : 0

  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = merge(local.labels, { app = "mongodb" })
  }

  spec {
    service_name = kubernetes_service_v1.mongodb[0].metadata[0].name
    replicas     = 1

    selector {
      match_labels = { app = "mongodb" }
    }

    template {
      metadata {
        labels = merge(local.labels, { app = "mongodb" })
      }

      spec {
        termination_grace_period_seconds = 30

        security_context {
          run_as_non_root = true
          run_as_user     = 999
          fs_group        = 999
        }

        container {
          name  = "mongodb"
          image = "mongo:7.0"

          port {
            container_port = 27017
          }

          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app.metadata[0].name
                key  = "MONGO_ROOT_USER"
              }
            }
          }

          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app.metadata[0].name
                key  = "MONGO_ROOT_PASSWORD"
              }
            }
          }

          env {
            name = "MONGO_INITDB_DATABASE"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.app.metadata[0].name
                key  = "MONGO_DB"
              }
            }
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }

          volume_mount {
            name       = "mongodb-data"
            mount_path = "/data/db"
          }

          liveness_probe {
            exec {
              command = ["mongosh", "--quiet", "--eval", "db.adminCommand('ping').ok"]
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["mongosh", "--quiet", "--eval", "db.adminCommand('ping').ok"]
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mongodb-data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "gp3"

        resources {
          requests = {
            storage = "20Gi"
          }
        }
      }
    }
  }
}
