###############################################################################
# Backend Server — Service + Deployment + HPA
###############################################################################

resource "kubernetes_service_v1" "server" {
  metadata {
    name      = "server"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = merge(local.labels, { app = "server" })
  }

  spec {
    selector = { app = "server" }
    type     = "ClusterIP"

    port {
      port        = 5001
      target_port = 5001
    }
  }
}

resource "kubernetes_deployment_v1" "server" {
  metadata {
    name      = "server"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = merge(local.labels, { app = "server" })
  }

  spec {
    replicas = var.server_replicas

    selector {
      match_labels = { app = "server" }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }

    template {
      metadata {
        labels = merge(local.labels, { app = "server" })
      }

      spec {
        # Spread across nodes for HA
        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
          label_selector {
            match_labels = { app = "server" }
          }
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 1001
          fs_group        = 1001
        }

        container {
          name              = "server"
          image             = var.server_image
          image_pull_policy = "Always"

          port {
            container_port = 5001
          }

          # Non-sensitive config from ConfigMap
          env {
            name = "NODE_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.app.metadata[0].name
                key  = "NODE_ENV"
              }
            }
          }

          env {
            name = "PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.app.metadata[0].name
                key  = "PORT"
              }
            }
          }

          # Secrets
          env {
            name = "JWT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app.metadata[0].name
                key  = "JWT_SECRET"
              }
            }
          }

          env {
            name = "MONGO_URI"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app.metadata[0].name
                key  = "MONGO_URI"
              }
            }
          }

          env {
            name = "REDIS_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app.metadata[0].name
                key  = "REDIS_URL"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = 5001
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/api/health"
              port = 5001
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          startup_probe {
            http_get {
              path = "/api/health"
              port = 5001
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            failure_threshold     = 12 # 60 s max cold start
          }
        }
      }
    }
  }

  # Avoid recreating pods when only the image tag changes in rolling deployments
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].image,
    ]
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "server" {
  metadata {
    name      = "server-hpa"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = local.labels
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.server.metadata[0].name
    }

    min_replicas = var.server_min_replicas
    max_replicas = var.server_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        select_policy                = "Min"
        policy {
          type           = "Percent"
          value          = 25
          period_seconds = 60
        }
      }

      scale_up {
        stabilization_window_seconds = 60
        select_policy                = "Max"
        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 60
        }
      }
    }
  }
}
