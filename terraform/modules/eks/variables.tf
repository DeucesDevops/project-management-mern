variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC ID where the cluster lives"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "Subnet IDs for the EKS control plane ENIs"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_group_instance_types" {
  description = "EC2 instance types for managed node groups"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "system_node_min" {
  type    = number
  default = 2
}

variable "system_node_max" {
  type    = number
  default = 4
}

variable "system_node_desired" {
  type    = number
  default = 2
}

variable "app_node_min" {
  type    = number
  default = 2
}

variable "app_node_max" {
  type    = number
  default = 10
}

variable "app_node_desired" {
  type    = number
  default = 3
}

variable "node_disk_size" {
  description = "Root EBS disk size (GiB) per node"
  type        = number
  default     = 50
}

variable "aws_region" {
  description = "AWS region (used in IAM policies)"
  type        = string
}
