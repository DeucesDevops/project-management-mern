###############################################################################
# Namespace, ConfigMap, Secret
###############################################################################

locals {
  labels = {
    "app.kubernetes.io/part-of"    = var.app_name
    "app.kubernetes.io/managed-by" = "terraform"
  }

  redis_scheme = var.redis_tls ? "rediss" : "redis"
  redis_url    = "${local.redis_scheme}://:${var.redis_password}@${var.redis_host}:${var.redis_port}"

  tls_suffix = var.mongo_tls ? "?tls=true&tlsCAFile=/etc/ssl/certs/ca-bundle.crt" : ""
  mongo_uri  = "mongodb://${var.mongo_root_user}:${var.mongo_root_password}@${var.mongo_host}:${var.mongo_port}/${var.mongo_db}?authSource=admin${local.tls_suffix}"
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name   = var.namespace
    labels = merge(local.labels, { environment = "production" })
  }
}

resource "kubernetes_config_map_v1" "app" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = local.labels
  }

  data = {
    NODE_ENV   = "production"
    PORT       = "5001"
    MONGO_DB   = var.mongo_db
    MONGO_HOST = var.mongo_host
    MONGO_PORT = var.mongo_port
    REDIS_HOST = var.redis_host
    REDIS_PORT = var.redis_port
  }
}

# ── Application Secrets ───────────────────────────────────────────────────────
# NOTE: Terraform stores secret values in state. For stricter security, replace
# this resource with the External Secrets Operator reading from AWS Secrets Manager.

resource "kubernetes_secret_v1" "app" {
  metadata {
    name      = "app-secrets"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = local.labels
  }

  type = "Opaque"

  data = {
    JWT_SECRET          = var.jwt_secret
    MONGO_ROOT_USER     = var.mongo_root_user
    MONGO_ROOT_PASSWORD = var.mongo_root_password
    REDIS_PASSWORD      = var.redis_password
    MONGO_URI           = local.mongo_uri
    REDIS_URL           = local.redis_url
  }
}
