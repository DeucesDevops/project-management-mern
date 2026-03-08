variable "cluster_name" {
  description = "Identifier prefix for ElastiCache resources"
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

variable "subnet_ids" {
  description = "Private subnet IDs for the ElastiCache subnet group"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID of EKS worker nodes (allowed to connect to Redis)"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_nodes" {
  description = "Number of cache nodes (≥2 enables multi-AZ failover)"
  type        = number
  default     = 1
}
