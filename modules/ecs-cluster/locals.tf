locals {
  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "ecs-cluster"
    },
    var.tags
  )
}