###############################################################################
# NetworkPolicies — default-deny then explicit allow per traffic path
###############################################################################

# ── Default deny all in the namespace ────────────────────────────────────────
resource "kubernetes_network_policy_v1" "default_deny" {
  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    pod_selector {} # applies to all pods
    policy_types = ["Ingress", "Egress"]
  }
}

# ── Allow DNS egress for all pods ─────────────────────────────────────────────
resource "kubernetes_network_policy_v1" "allow_dns" {
  metadata {
    name      = "allow-dns-egress"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

# ── Allow ingress traffic to the client (from ALB) ───────────────────────────
resource "kubernetes_network_policy_v1" "allow_ingress_to_client" {
  metadata {
    name      = "allow-ingress-to-client"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = { app = "client" }
    }
    policy_types = ["Ingress"]

    ingress {
      ports {
        port = "80"
      }
    }
  }
}

# ── Allow ingress traffic to the server (from ALB + client) ──────────────────
resource "kubernetes_network_policy_v1" "allow_ingress_to_server" {
  metadata {
    name      = "allow-ingress-to-server"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = { app = "server" }
    }
    policy_types = ["Ingress"]

    ingress {
      ports {
        port = "5001"
      }
    }
  }
}

# ── Allow server → MongoDB ────────────────────────────────────────────────────
resource "kubernetes_network_policy_v1" "allow_server_to_mongodb" {
  count = local.deploy_mongodb ? 1 : 0

  metadata {
    name      = "allow-server-to-mongodb"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = { app = "mongodb" }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { app = "server" }
        }
      }
      ports {
        port = "27017"
      }
    }
  }
}

# ── Allow server → Redis ──────────────────────────────────────────────────────
resource "kubernetes_network_policy_v1" "allow_server_to_redis" {
  count = local.deploy_redis ? 1 : 0

  metadata {
    name      = "allow-server-to-redis"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = { app = "redis" }
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = { app = "server" }
        }
      }
      ports {
        port = "6379"
      }
    }
  }
}

# ── Server egress → MongoDB + Redis (+ external if using managed services) ───
resource "kubernetes_network_policy_v1" "server_egress" {
  metadata {
    name      = "allow-server-egress"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = { app = "server" }
    }
    policy_types = ["Egress"]

    # In-cluster MongoDB
    dynamic "egress" {
      for_each = local.deploy_mongodb ? [1] : []
      content {
        to {
          pod_selector {
            match_labels = { app = "mongodb" }
          }
        }
        ports {
          port = "27017"
        }
      }
    }

    # In-cluster Redis
    dynamic "egress" {
      for_each = local.deploy_redis ? [1] : []
      content {
        to {
          pod_selector {
            match_labels = { app = "redis" }
          }
        }
        ports {
          port = "6379"
        }
      }
    }

    # Managed services (DocumentDB / ElastiCache) — allow egress to any IP in the VPC
    dynamic "egress" {
      for_each = (!local.deploy_mongodb || !local.deploy_redis) ? [1] : []
      content {
        ports {
          port = local.deploy_mongodb ? "6379" : "27017"
        }
      }
    }

    # DNS
    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

# ── Client egress → server ────────────────────────────────────────────────────
resource "kubernetes_network_policy_v1" "client_egress" {
  metadata {
    name      = "allow-client-egress"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = { app = "client" }
    }
    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = { app = "server" }
        }
      }
      ports {
        port = "5001"
      }
    }

    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}
