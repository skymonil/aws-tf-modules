variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "distribution_config" {
  description = "The core technical configuration for the CloudFront Distribution"
  type = object({
    # --- FRONTEND (S3) ---
    s3_origin_domain_name = string
    acm_certificate_arn   = string

    # --- BACKEND (API GW, Public ALB, or Private ALB) ---
    api_domain_name    = optional(string, null) 
    api_vpc_origin_arn = optional(string, null) # Provide this ONLY for Private ALBs/EC2s Amazon Resource Name (ARN) of an Internal Application Load Balancer (ALB) that lives completely hidden inside your private subnets

    # --- POLICIES (With AWS Managed Defaults) ---
    api_cache_policy_id            = optional(string, "4135ea2d-6df8-44a3-9df3-4b5a84be39ad") # Default: CachingDisabled
    api_origin_request_policy_id   = optional(string, "216adef6-5c7f-47e4-b989-5492eafa07d3") # Default: AllViewer
    api_response_headers_policy_id = optional(string, null) # Pass your CORS Policy ID here

    default_cache_policy_id            = optional(string, "658327ea-f89d-4fab-a63d-7e88639e58f6") # Default: CachingOptimized
    default_response_headers_policy_id = optional(string, null)
    
    # --- MISC ---
    aliases     = optional(list(string), [])
    waf_arn     = optional(string, null)
    price_class = optional(string, "PriceClass_100")
  })
}