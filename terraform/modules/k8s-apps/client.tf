###############################################################################
# Frontend Client (Nginx) — Service + Deployment + HPA
###############################################################################

resource "kubernetes_service_v1" "client" {
  metadata {
    name      = "client"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = merge(local.labels, { app = "client" })
  }

  spec {
    selector = { app = "client" }
    type     = "ClusterIP"

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment_v1" "client" {
  metadata {
    name      = "client"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = merge(local.labels, { app = "client" })
  }

  spec {
    replicas = var.client_replicas

    selector {
      match_labels = { app = "client" }
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
        labels = merge(local.labels, { app = "client" })
      }

      spec {
        topology_spread_constraint {
          max_skew           = 1
          topology_key       = "kubernetes.io/hostname"
          when_unsatisfiable = "DoNotSchedule"
          label_selector {
            match_labels = { app = "client" }
          }
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 101 # nginx user in nginx:alpine
          fs_group        = 101
        }

        container {
          name              = "client"
          image             = var.client_image
          image_pull_policy = "Always"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].image,
    ]
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "client" {
  metadata {
    name      = "client-hpa"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = local.labels
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.client.metadata[0].name
    }

    min_replicas = var.client_min_replicas
    max_replicas = var.client_max_replicas

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
  }
}
