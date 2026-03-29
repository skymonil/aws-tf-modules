locals {

  common_tags = merge(

    {
      ManagedBy = "Terraform"
      Module    = "ecr-repository"
    },
    var.tags
  )
}