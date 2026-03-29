# 1. Origin Access Control (The modern, secure way to access S3)
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} S3 Origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. VPC Origin (The New Magic Door into your Private Subnet)
resource "aws_cloudfront_vpc_origin" "alb" {
  # Only provision this if an ALB ARN is provided
  count = var.distribution_config.alb_arn != null ? 1 : 0

  vpc_origin_endpoint_config {
    name                   = "${var.project_name}-private-alb"
    arn                    = var.distribution_config.alb_arn
    http_port              = 80
    https_port             = 443
    
    # Since traffic never leaves the AWS private fiber backbone,
    # many teams use http-only to avoid managing SSL certs on the internal ALB.
    # Change to https-only if your compliance requires end-to-end encryption.
    origin_protocol_policy = "http-only" 

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

# 2. The Global Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.project_name}"
  default_root_object = "index.html"
  
 # Reference the object fields
  web_acl_id          = var.distribution_config.waf_arn
  aliases             = var.distribution_config.aliases
  price_class         = var.distribution_config.price_class

  # The S3 Bucket we are pulling data from
  origin {
    # Reference the object fields
    domain_name              = var.distribution_config.s3_origin_domain_name
    origin_id                = "S3-${var.project_name}-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # 2. The Dynamic Backend Origin (ALB)
  # This block only renders if an alb_origin_domain_name is provided!
  dynamic "origin" {
    for_each = var.distribution_config.alb_arn != null ? [1] : []
    content {
      domain_name = var.distribution_config.alb_domain_name
      origin_id   = "ALB-${var.project_name}-origin"

      # ALBs require a custom_origin_config, NOT an origin_access_control
      vpc_origin_config {
        vpc_origin_id            = aws_cloudfront_vpc_origin.alb[0].id
        origin_keepalive_timeout = 5
        origin_read_timeout      = 30
      }
    }
  }

  # ---------------------------------------------------------
  # CACHE BEHAVIORS (ROUTING)
  # ---------------------------------------------------------

  # 1. The API Router (Ordered Cache Behavior)
  # CloudFront checks this first. If the path is /api/*, it goes to the ALB.
  dynamic "ordered_cache_behavior" {
    for_each =var.distribution_config.alb_arn != null ? [1] : []
    content {
      path_pattern           = "/api/*"
      target_origin_id       = "ALB-${var.project_name}-origin"
      viewer_protocol_policy = "redirect-to-https"

      # APIs usually need all HTTP methods (POST, PUT, DELETE)
      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

       # AWS Managed Policy: CachingDisabled
      cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

      # CRITICAL FOR APIs: Forward all Auth headers, cookies, and query strings to the ALB
      # AWS Managed Policy: AllViewer
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

      compress = true
    }
  }

  # 2. The Fallback Router (Default Cache Behavior)
  # If the path is NOT /api/*, it falls back to this rule and goes to S3.
  default_cache_behavior {
    target_origin_id       = "S3-${var.project_name}-origin"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # AWS Managed Policy: CachingOptimized (Good for React static files)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    compress = true
  }
  
   viewer_certificate {
    # Reference the object fields
    acm_certificate_arn            = var.distribution_config.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }



  # SPA Routing: Map 404s back to index.html for React/Vue apps
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }
  
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  
  

 

  restrictions {
    geo_restriction {
      restriction_type = "none" # Can be changed to whitelist/blacklist countries
    }
  }

  tags = local.common_tags
}
# 1. Origin Access Control (The modern, secure way to access S3)
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} S3 Origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. The Global Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.project_name}"
  default_root_object = "index.html"
  
 # Reference the object fields
  web_acl_id          = var.distribution_config.waf_arn
  aliases             = var.distribution_config.aliases
  price_class         = var.distribution_config.price_class

  # The S3 Bucket we are pulling data from
  origin {
    # Reference the object fields
    domain_name              = var.distribution_config.s3_origin_domain_name
    origin_id                = "S3-${var.project_name}-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # 2. The Dynamic Backend Origin (ALB)
  # This block only renders if an alb_origin_domain_name is provided!
  dynamic "origin" {
    for_each = var.distribution_config.alb_origin_domain_name != null ? [1] : []
    content {
      domain_name = var.distribution_config.alb_origin_domain_name
      origin_id   = "ALB-${var.project_name}-origin"

      # ALBs require a custom_origin_config, NOT an origin_access_control
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # ---------------------------------------------------------
  # CACHE BEHAVIORS (ROUTING)
  # ---------------------------------------------------------

  # 1. The API Router (Ordered Cache Behavior)
  # CloudFront checks this first. If the path is /api/*, it goes to the ALB.
  dynamic "ordered_cache_behavior" {
    for_each = var.distribution_config.alb_origin_domain_name != null ? [1] : []
    content {
      path_pattern           = "/api/*"
      target_origin_id       = "ALB-${var.project_name}-origin"
      viewer_protocol_policy = "redirect-to-https"

      # APIs usually need all HTTP methods (POST, PUT, DELETE)
      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

      # CRITICAL FOR APIs: Do not cache API responses! 
      # AWS Managed Policy: CachingDisabled
      cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

      # CRITICAL FOR APIs: Forward all Auth headers, cookies, and query strings to the ALB
      # AWS Managed Policy: AllViewer
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

      compress = true
    }
  }

  # 2. The Fallback Router (Default Cache Behavior)
  # If the path is NOT /api/*, it falls back to this rule and goes to S3.
  default_cache_behavior {
    target_origin_id       = "S3-${var.project_name}-origin"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # AWS Managed Policy: CachingOptimized (Good for React static files)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    compress = true
  }
  
   viewer_certificate {
    # Reference the object fields
    acm_certificate_arn            = var.distribution_config.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # The Default Routing Behavior
  default_cache_behavior {
    target_origin_id       = "S3-${var.project_name}-origin"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Using AWS Managed Caching Policy (CachingOptimized)
    # This prevents you from having to write complex custom cache rules
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    compress = true
  }

  # SPA Routing: Map 404s back to index.html for React/Vue apps
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }
  
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  
  }

 

  restrictions {
    geo_restriction {
      restriction_type = "none" # Can be changed to whitelist/blacklist countries
    }
  }
}
  tags = local.common_tags
}