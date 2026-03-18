variable "cluster_name"      { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "node_iam_role_arn" {
  type    = string
  default = ""
}
