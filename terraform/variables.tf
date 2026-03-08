###############################################################################
# Root Input Variables
###############################################################################

# ── General ───────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "project-mgmt"
}

variable "environment" {
  description = "Deployment environment: dev | staging | production"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Must be one of: dev, staging, production."
  }
}

# ── VPC ───────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of AZs to spread across (2 or 3)"
  type        = number
  default     = 3
}

# ── EKS ──────────────────────────────────────────────────────────────────────

variable "cluster_version" {
  type    = string
  default = "1.30"
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Restrict API endpoint to these CIDRs (use your IP in production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_group_instance_types" {
  type    = list(string)
  default = ["t3.medium", "t3a.medium"]
}

variable "node_group_min_size" {
  type    = number
  default = 2
}

variable "node_group_max_size" {
  type    = number
  default = 10
}

variable "node_group_desired_size" {
  type    = number
  default = 3
}

variable "node_disk_size" {
  type    = number
  default = 50
}

# ── ECR ──────────────────────────────────────────────────────────────────────

variable "ecr_image_retention_count" {
  type    = number
  default = 10
}

# ── Secrets (sensitive) ───────────────────────────────────────────────────────
# Leave null to auto-generate a random value.

variable "jwt_secret" {
  description = "JWT signing secret. Auto-generated if null."
  type        = string
  default     = null
  sensitive   = true
}

variable "mongo_root_user" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "mongo_root_password" {
  description = "MongoDB root password. Auto-generated if null."
  type        = string
  default     = null
  sensitive   = true
}

variable "redis_password" {
  description = "Redis AUTH password. Auto-generated if null."
  type        = string
  default     = null
  sensitive   = true
}

# ── MongoDB Config ────────────────────────────────────────────────────────────

variable "mongo_db" {
  type    = string
  default = "project_management"
}

# ── Optional: DocumentDB ──────────────────────────────────────────────────────

variable "enable_documentdb" {
  description = "Replace in-cluster MongoDB with Amazon DocumentDB"
  type        = bool
  default     = false
}

variable "docdb_master_username" {
  type    = string
  default = "admin"
}

variable "docdb_instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "docdb_instance_count" {
  type    = number
  default = 2
}

# ── Optional: ElastiCache ─────────────────────────────────────────────────────

variable "enable_elasticache" {
  description = "Replace in-cluster Redis with Amazon ElastiCache"
  type        = bool
  default     = false
}

variable "elasticache_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "elasticache_num_cache_nodes" {
  type    = number
  default = 1
}

# ── Kubernetes ────────────────────────────────────────────────────────────────

variable "k8s_namespace" {
  description = "Kubernetes namespace for all app resources"
  type        = string
  default     = "project-mgmt"
}

variable "server_image" {
  description = "Server Docker image (defaults to ECR :latest if empty)"
  type        = string
  default     = ""
}

variable "client_image" {
  description = "Client Docker image (defaults to ECR :latest if empty)"
  type        = string
  default     = ""
}

variable "server_replicas"     { type = number; default = 2 }
variable "server_min_replicas" { type = number; default = 2 }
variable "server_max_replicas" { type = number; default = 10 }
variable "client_replicas"     { type = number; default = 2 }
variable "client_min_replicas" { type = number; default = 2 }
variable "client_max_replicas" { type = number; default = 6 }

# ── Ingress ───────────────────────────────────────────────────────────────────

variable "app_domain" {
  description = "Public hostname (e.g. app.example.com)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "alb_logs_bucket" {
  description = "S3 bucket for ALB access logs (empty = disabled)"
  type        = string
  default     = ""
}
