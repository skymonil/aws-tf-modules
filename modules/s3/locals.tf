locals {

  common_tags = merge(

    {

      ManagedBy = "Terraform"
      Module    = "s3-bucket"

    },

    var.tags

  )

}