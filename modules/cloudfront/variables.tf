variable "tags" {

  description = "Tags applied to "

  type = map(string)

  default = {}

}



variable "distribution_config" {
  description = "The core technical configuration for the CloudFront Distribution"
  type = object({
    s3_origin_domain_name = string
    acm_certificate_arn   = string

    alb_arn = optional(string, null)
    alb_domain_name =  optional(string, null)
    
    # Optional fields with built-in production defaults
    aliases     = optional(list(string), [])
    waf_arn     = optional(string, null)
    price_class = optional(string, "PriceClass_100")
  })
}