locals {

  common_tags = merge(

    {

      ManagedBy = "Terraform"
      Module    = "iam-policy"

    },

    var.tags

  )

}