variable "namespace" {
  description = "Kubernetes namespace for all app resources"
  type        = string
  default     = "project-mgmt"
}

variable "app_name" {
  description = "Application name label applied to all resources"
  type        = string
  default     = "project-mgmt"
}

# ── Images ────────────────────────────────────────────────────────────────────

variable "server_image" {
  description = "Full Docker image reference for the server (e.g. ECR URL:tag)"
  type        = string
}

variable "client_image" {
  description = "Full Docker image reference for the client (e.g. ECR URL:tag)"
  type        = string
}

# ── Replicas ─────────────────────────────────────────────────────────────────

variable "server_replicas" {
  type    = number
  default = 2
}

variable "server_min_replicas" {
  type    = number
  default = 2
}

variable "server_max_replicas" {
  type    = number
  default = 10
}

variable "client_replicas" {
  type    = number
  default = 2
}

variable "client_min_replicas" {
  type    = number
  default = 2
}

variable "client_max_replicas" {
  type    = number
  default = 6
}

# ── Secrets (sensitive) ───────────────────────────────────────────────────────

variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}

variable "mongo_root_user" {
  description = "MongoDB root username"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "mongo_root_password" {
  description = "MongoDB root password"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis AUTH password"
  type        = string
  sensitive   = true
}

# ── MongoDB ───────────────────────────────────────────────────────────────────

variable "mongo_db" {
  description = "MongoDB database name"
  type        = string
  default     = "project_management"
}

variable "mongo_host" {
  description = "MongoDB hostname (in-cluster = 'mongodb', managed = DocumentDB endpoint)"
  type        = string
  default     = "mongodb"
}

variable "mongo_port" {
  description = "MongoDB port"
  type        = string
  default     = "27017"
}

variable "mongo_tls" {
  description = "Append ?tls=true to MongoDB URI (required for DocumentDB)"
  type        = bool
  default     = false
}

# ── Redis ─────────────────────────────────────────────────────────────────────

variable "redis_host" {
  description = "Redis hostname (in-cluster = 'redis', managed = ElastiCache endpoint)"
  type        = string
  default     = "redis"
}

variable "redis_port" {
  description = "Redis port"
  type        = string
  default     = "6379"
}

variable "redis_tls" {
  description = "Use rediss:// scheme (required for ElastiCache with TLS)"
  type        = bool
  default     = false
}

# ── Ingress ───────────────────────────────────────────────────────────────────

variable "app_domain" {
  description = "Public hostname for the application (e.g. app.example.com)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs (leave empty to disable)"
  type        = string
  default     = ""
}
