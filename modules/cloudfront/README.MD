### Where does `api_vpc_origin_arn` come from?

Before we get to the README, let's answer your architectural question. This is a crucial concept in modern AWS design.

The `api_vpc_origin_arn` is the **Amazon Resource Name (ARN) of an Internal Application Load Balancer (ALB)** that lives completely hidden inside your private subnets. 



In your root `envs/prod/main.tf`, you will have a module that creates your ALB. You simply take the output of that ALB module and feed it into your CloudFront module. It looks exactly like this:

```hcl
# 1. Create the Internal ALB (Notice: internal = true)
module "app_alb" {
  source = "../../modules/alb"
  
  name               = "dronapay-internal-alb"
  internal           = true # 🚨 It has no public IP!
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.private_subnet_ids
}

# 2. Pass it into the CloudFront Module
module "cdn" {
  source = "../../modules/cloudfront"

  project_name = "dronapay"
  
  distribution_config = {
    s3_origin_domain_name = module.frontend_bucket.bucket_regional_domain_name
    acm_certificate_arn   = var.global_cert_arn
    
    # Here is the magic:
    api_domain_name    = module.app_alb.alb_dns_name
    api_vpc_origin_arn = module.app_alb.alb_arn      # <--- Passed right here!
  }
}
```

By passing that ARN, CloudFront provisions a hidden AWS-managed endpoint (the VPC Origin) inside your VPC. This allows the global CDN to securely tunnel traffic directly into your private Fargate containers without *ever* touching the public internet.

---

### The CloudFront Module README.md

Here is the production-ready documentation for your new edge-routing module.

````markdown
# AWS CloudFront Edge Router Module

A highly dynamic, production-ready AWS CloudFront module designed for modern Single-Page Applications (SPAs) and microservice architectures.

This module acts as a global Edge Router. It securely serves static frontend assets from a private S3 bucket while simultaneously routing dynamic API requests (`/api/*`) to backend services. It natively supports both Public APIs (API Gateway) and completely Private APIs (Internal ALBs via VPC Origins).

## ✨ Features

* **VPC Origin Support:** Securely route traffic from the CDN directly to Internal Load Balancers in private subnets—no public IPs required on your ALBs.
* **Modern S3 Security:** Uses Origin Access Control (OAC) to ensure your S3 bucket remains entirely private and is only accessible via CloudFront.
* **HTTP/3 & QUIC:** Natively enabled for ultra-low latency and superior connection handling on mobile and high-latency networks.
* **Smart SPA Routing:** Automatically intercepts 404/403 errors and rewrites them to `index.html` to support React, Vue, and Angular client-side routing.
* **Dynamic Policy Injection:** Easily attach custom Cache Policies, Origin Request Policies, and Response Headers Policies (for CORS) to your routes.

---

## 🚀 Usage Examples

### Scenario A: Private API (Internal ALB via VPC Origin)
Use this architecture when your backend runs on ECS Fargate or EC2 in private subnets.

```hcl
module "cdn" {
  source = "../../modules/cloudfront"

  project_name = "dronapay-prod"

  distribution_config = {
    s3_origin_domain_name = "dronapay-frontend-prod.s3.ap-south-1.amazonaws.com"
    acm_certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/xyz"
    
    # Triggers VPC Origin Creation
    api_domain_name    = module.internal_alb.dns_name
    api_vpc_origin_arn = module.internal_alb.arn 

    # Attach a custom CORS policy
    api_response_headers_policy_id = aws_cloudfront_response_headers_policy.cors.id
  }
}
````

### Scenario B: Serverless Public API (API Gateway)
Use this architecture when your backend is built on AWS API Gateway and Lambda.

```hcl
module "cdn" {
  source = "../../modules/cloudfront"

  project_name = "dronapay-serverless"

  distribution_config = {
    s3_origin_domain_name = "dronapay-frontend-dev.s3.ap-south-1.amazonaws.com"
    acm_certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/xyz"
    
    # Omitting the ARN triggers a standard Custom HTTPS Origin
    api_domain_name = "abc123xyz.execute-api.ap-south-1.amazonaws.com"
  }
}
```

---

## 📋 Requirements

| Name | Version |
|------|---------|
| \<a name="requirement\_terraform"\>\</a\> [terraform](https://www.google.com/search?q=%23requirement_terraform) | \>= 1.5.0 |
| \<a name="requirement\_aws"\>\</a\> [aws](https://www.google.com/search?q=%23requirement_aws) | \~\> 5.0 |

---

## 📥 Inputs

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| `project_name` | Name of the project (used for resource naming) | `string` | **yes** |
| `distribution_config` | Core technical configuration object for the distribution | `object` | **yes** |
| `tags` | Tags applied to all resources | `map(string)` | no |

### `distribution_config` Object Structure

| Property | Description | Default |
|----------|-------------|---------|
| `s3_origin_domain_name` | Regional domain name of the S3 bucket | **Required** |
| `acm_certificate_arn` | ARN of the SSL cert (Must be in `us-east-1`) | **Required** |
| `api_domain_name` | DNS name of the ALB or API Gateway | `null` |
| `api_vpc_origin_arn` | ARN of an Internal ALB (triggers VPC Origin) | `null` |
| `api_cache_policy_id` | Cache policy for `/api/*` | `AWS: CachingDisabled` |
| `api_origin_request_policy_id`| Origin Request policy for `/api/*` | `AWS: AllViewer` |
| `api_response_headers_policy_id`| Response Headers policy (e.g., CORS) for `/api/*`| `null` |
| `default_cache_policy_id` | Cache policy for static assets | `AWS: CachingOptimized` |
| `default_response_headers_policy_id`| Response Headers policy for static assets | `null` |
| `aliases` | List of custom domain names (e.g., `["www.app.com"]`) | `[]` |
| `waf_arn` | ARN of the AWS WAF WebACL to attach | `null` |
| `price_class` | CloudFront Price Class | `"PriceClass_100"` |

---

## 📤 Outputs

| Name | Description |
|------|-------------|
| `distribution_id` | The internal identifier for the distribution. |
| `distribution_domain_name` | The raw CloudFront domain name (e.g., `d604721fxaaqy9.cloudfront.net`). |
| `hosted_zone_id` | The Route 53 zone ID used for routing Alias records. |

```