variable "project_name" {
  description = "Name prefix for ECR repository names"
  type        = string
}

variable "image_retention_count" {
  description = "Number of images to keep per repository"
  type        = number
  default     = 10
}
