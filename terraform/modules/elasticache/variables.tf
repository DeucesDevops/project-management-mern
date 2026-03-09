variable "cluster_name" {
  description = "EKS cluster name (used as resource name prefix)"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "EKS node security group ID (granted ingress to Redis)"
  type        = string
}

variable "enable_elasticache" {
  description = "Create the ElastiCache Redis cluster"
  type        = bool
  default     = false
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of ElastiCache nodes"
  type        = number
  default     = 1
}
