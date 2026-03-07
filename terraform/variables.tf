###############################################################################
# Input Variables
###############################################################################

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix used for all resource names"
  type        = string
  default     = "project-mgmt"
}

variable "environment" {
  description = "Deployment environment (dev | staging | production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production"
  }
}

# ── VPC ───────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use (2 or 3)"
  type        = number
  default     = 3
}

# ── EKS ──────────────────────────────────────────────────────────────────────

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API server endpoint is publicly accessible"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the EKS public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict in production to known IPs
}

# ── Node Groups ───────────────────────────────────────────────────────────────

variable "node_group_instance_types" {
  description = "EC2 instance types for the general-purpose node group"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the managed node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes (used by Cluster Autoscaler)"
  type        = number
  default     = 10
}

variable "node_group_desired_size" {
  description = "Desired number of nodes at launch"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Root EBS disk size (GiB) for each node"
  type        = number
  default     = 50
}

# ── ECR ──────────────────────────────────────────────────────────────────────

variable "ecr_image_retention_count" {
  description = "Number of recent images to retain per ECR repository"
  type        = number
  default     = 10
}

# ── DocumentDB (MongoDB-compatible) ──────────────────────────────────────────

variable "enable_documentdb" {
  description = "Create an Amazon DocumentDB cluster for MongoDB storage"
  type        = bool
  default     = false # Set true to use managed DocumentDB instead of in-cluster MongoDB
}

variable "docdb_instance_class" {
  description = "DocumentDB instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "docdb_instance_count" {
  description = "Number of DocumentDB instances"
  type        = number
  default     = 2
}

variable "docdb_master_username" {
  description = "Master username for DocumentDB"
  type        = string
  default     = "admin"
}

# ── ElastiCache (Redis) ───────────────────────────────────────────────────────

variable "enable_elasticache" {
  description = "Create an Amazon ElastiCache Redis cluster"
  type        = bool
  default     = false # Set true to use managed Redis instead of in-cluster Redis
}

variable "elasticache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of ElastiCache nodes"
  type        = number
  default     = 1
}
