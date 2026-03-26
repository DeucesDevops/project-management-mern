output "alb_controller_role_arn" { value = module.alb_controller_irsa.iam_role_arn }
output "external_dns_role_arn"   { value = module.external_dns_irsa.iam_role_arn }
output "karpenter_role_arn"      { value = module.karpenter_irsa.iam_role_arn }
