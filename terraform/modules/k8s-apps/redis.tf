###############################################################################
# Redis — Service + Deployment
# Only deployed when using in-cluster Redis (redis_host == "redis")
###############################################################################

locals {
  deploy_redis = var.redis_host == "redis"
}

resource "kubernetes_service_v1" "redis" {
  count = local.deploy_redis ? 1 : 0

  metadata {
    name      = "redis"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = merge(local.labels, { app = "redis" })
  }

  spec {
    selector = { app = "redis" }

    port {
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_deployment_v1" "redis" {
  count = local.deploy_redis ? 1 : 0

  metadata {
    name      = "redis"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = merge(local.labels, { app = "redis" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "redis" }
    }

    template {
      metadata {
        labels = merge(local.labels, { app = "redis" })
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 999
          fs_group        = 999
        }

        container {
          name  = "redis"
          image = "redis:7.2-alpine"

          command = [
            "redis-server",
            "--appendonly", "yes",
            "--requirepass", "$(REDIS_PASSWORD)",
            "--maxmemory", "256mb",
            "--maxmemory-policy", "allkeys-lru",
          ]

          port {
            container_port = 6379
          }

          env {
            name = "REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app.metadata[0].name
                key  = "REDIS_PASSWORD"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }

          liveness_probe {
            exec {
              command = ["sh", "-c", "redis-cli -a \"$REDIS_PASSWORD\" ping | grep PONG"]
            }
            initial_delay_seconds = 15
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["sh", "-c", "redis-cli -a \"$REDIS_PASSWORD\" ping | grep PONG"]
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "redis-data"
          empty_dir {}
          # For persistence, replace with a PVC:
          # persistent_volume_claim { claim_name = kubernetes_persistent_volume_claim_v1.redis.metadata[0].name }
        }
      }
    }
  }
}
