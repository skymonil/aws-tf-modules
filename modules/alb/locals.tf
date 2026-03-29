locals {

  common_tags = merge(

    {

      ManagedBy = "Terraform"
      Module    = ""

    },

    var.tags

  )

}