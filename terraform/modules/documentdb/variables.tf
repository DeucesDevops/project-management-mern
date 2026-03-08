variable "cluster_name" {
  description = "Identifier prefix for DocumentDB resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DocumentDB subnet group"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID of EKS worker nodes (allowed to connect to DocumentDB)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "master_username" {
  description = "Master username for DocumentDB"
  type        = string
  default     = "admin"
}

variable "instance_class" {
  description = "DocumentDB instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "instance_count" {
  description = "Number of DocumentDB instances"
  type        = number
  default     = 2
}
