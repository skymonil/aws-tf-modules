locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })
}

# 1. Origin Access Control (The modern, secure way to access S3)
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} S3 Origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. VPC Origin (The New Magic Door into your Private Subnet)
resource "aws_cloudfront_vpc_origin" "api" {
  # Only provision this if a VPC Origin ARN is provided
  count = var.distribution_config.api_vpc_origin_arn != null ? 1 : 0

  vpc_origin_endpoint_config {
    name                   = "${var.project_name}-private-alb"
    arn                    = var.distribution_config.api_vpc_origin_arn
    http_port              = 80
    https_port             = 443
    
    # Since traffic never leaves the AWS private fiber backbone,
    # many teams use http-only to avoid managing SSL certs on the internal ALB.
    origin_protocol_policy = "http-only" 

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

# 3. The Global Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.project_name}"
  default_root_object = "index.html"
  http_version        = "http2and3"

  web_acl_id  = var.distribution_config.waf_arn
  aliases     = var.distribution_config.aliases
  price_class = var.distribution_config.price_class

  # --- FRONTEND ORIGIN (S3) ---
  origin {
    domain_name              = var.distribution_config.s3_origin_domain_name
    origin_id                = "S3-${var.project_name}-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # --- BACKEND ORIGIN (Dynamic) ---
  dynamic "origin" {
    for_each = var.distribution_config.api_domain_name != null ? [1] : []
    content {
      domain_name = var.distribution_config.api_domain_name
      origin_id   = "API-${var.project_name}-origin"

      # Scenario A: Private ALB (VPC Origin)
      dynamic "vpc_origin_config" {
        for_each = var.distribution_config.api_vpc_origin_arn != null ? [1] : []
        content {
          vpc_origin_id            = aws_cloudfront_vpc_origin.api[0].id
          origin_keepalive_timeout = 5
          origin_read_timeout      = 30
        }
      }

      # Scenario B: Public ALB or API Gateway (Custom Origin)
      dynamic "custom_origin_config" {
        for_each = var.distribution_config.api_vpc_origin_arn == null ? [1] : []
        content {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
    }
  }

  # ---------------------------------------------------------
  # CACHE BEHAVIORS (ROUTING)
  # ---------------------------------------------------------

  # 1. The API Router (Ordered Cache Behavior)
  dynamic "ordered_cache_behavior" {
    for_each = var.distribution_config.api_domain_name != null ? [1] : []
    content {
      path_pattern           = "/api/*"
      target_origin_id       = "API-${var.project_name}-origin"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

      # Injectable Policies (Uses your custom ones, or falls back to AWS Defaults)
      cache_policy_id            = var.distribution_config.api_cache_policy_id
      origin_request_policy_id   = var.distribution_config.api_origin_request_policy_id
      response_headers_policy_id = var.distribution_config.api_response_headers_policy_id

      compress = true
    }
  }

  # 2. The Fallback Router (Default Cache Behavior)
  default_cache_behavior {
    target_origin_id       = "S3-${var.project_name}-origin"
    viewer_protocol_policy = "redirect-to-https"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Injectable Policies
    cache_policy_id            = var.distribution_config.default_cache_policy_id
    response_headers_policy_id = var.distribution_config.default_response_headers_policy_id

    compress = true
  }
  
  viewer_certificate {
    acm_certificate_arn      = var.distribution_config.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
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

  tags = local.common_tags
}