locals {

  common_tags = merge(

    {

      ManagedBy = "Terraform"
      Module    = "Cloudfront"

    },

    var.tags

  )

}