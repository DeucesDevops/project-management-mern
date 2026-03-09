variable "project_name" {
  description = "Name prefix used for ECR repository names"
  type        = string
}

variable "image_retention_count" {
  description = "Number of recent images to retain per repository"
  type        = number
  default     = 10
}
