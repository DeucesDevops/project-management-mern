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
  description = "EKS node security group ID (granted ingress to DocumentDB)"
  type        = string
}

variable "enable_documentdb" {
  description = "Create the DocumentDB cluster"
  type        = bool
  default     = false
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

variable "master_username" {
  description = "Master username for DocumentDB"
  type        = string
  default     = "admin"
}
