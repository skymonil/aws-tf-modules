locals {

  common_tags = merge(

    {

      ManagedBy = "Terraform"
      Module    = "iam-role"

    },

    var.tags

  )

}