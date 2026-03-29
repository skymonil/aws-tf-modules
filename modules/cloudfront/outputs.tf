output "distribution_id" {
  description = "The identifier for the distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_domain_name" {
  description = "The domain name corresponding to the distribution (e.g. d604721fxaaqy9.cloudfront.net)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID that can be used to route an Alias record."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}