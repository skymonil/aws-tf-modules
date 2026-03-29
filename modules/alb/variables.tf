variable "tags" {

  description = "Tags applied to "

  type = map(string)

  default = {}

}

variable "alb_name" {
  description = "The name of the load balancer"
  type        = string
}

variable "alb_config" {
  description = "The core configuration for the Internal ALB, Network, and Target Group"
  type = object({
    # Required Network Inputs (No defaults)
    vpc_id             = string
    private_subnet_ids = list(string)
    security_group_ids = list(string)

    # Optional Target Group Settings
    backend_port      = optional(number, 8080)
    health_check_path = optional(string, "/health")

    certificate_arn    = optional(string, null)

    # Optional Security & Logging Settings
    enable_deletion_protection = optional(bool, true)
    enable_access_logs         = optional(bool, true)
    access_log_bucket_name     = optional(string, null)
  })
}