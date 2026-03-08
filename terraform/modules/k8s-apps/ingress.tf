###############################################################################
# ALB Ingress — routes /api/* → server, /* → client
###############################################################################

locals {
  alb_access_logs = var.alb_logs_bucket != "" ? {
    "alb.ingress.kubernetes.io/load-balancer-attributes" = join(",", [
      "access_logs.s3.enabled=true",
      "access_logs.s3.bucket=${var.alb_logs_bucket}",
      "idle_timeout.timeout_seconds=60",
    ])
  } : {}
}

resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "app-ingress"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = local.labels

    annotations = merge(
      {
        "kubernetes.io/ingress.class"                              = "alb"
        "alb.ingress.kubernetes.io/scheme"                        = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"                   = "ip"
        "alb.ingress.kubernetes.io/listen-ports"                  = "[{\"HTTP\":80},{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"                  = "443"
        "alb.ingress.kubernetes.io/certificate-arn"               = var.acm_certificate_arn
        "alb.ingress.kubernetes.io/healthcheck-path"              = "/api/health"
        "alb.ingress.kubernetes.io/healthcheck-interval-seconds"  = "30"
        "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"   = "10"
        "alb.ingress.kubernetes.io/healthy-threshold-count"       = "2"
        "alb.ingress.kubernetes.io/unhealthy-threshold-count"     = "3"
      },
      local.alb_access_logs
    )
  }

  spec {
    rule {
      host = var.app_domain

      http {
        # /api/* → backend server
        path {
          path      = "/api"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.server.metadata[0].name
              port { number = 5001 }
            }
          }
        }

        # /* → React frontend
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.client.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true
}
