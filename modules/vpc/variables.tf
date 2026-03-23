variable "vpc_cidr_block" {
  type        = string
  description = "Primary CIDR block for the VPC"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block)) && tonumber(split("/", var.vpc_cidr_block)[1]) <= 24
    error_message = "Must be a valid CIDR block with a mask of /24 or smaller (e.g., /24, /23, /22, etc.)."
  }
}

variable "region" {
  type        = string
  description = "AWS Region"
}



variable "subnet_config" {
  description = "A map mapping Availability Zones to their public and private CIDR configurations."
  
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))

  # Optional: You can still add validation to ensure at least one AZ is provided
  validation {
    condition     = length(var.subnet_config) > 0
    error_message = "You must provide configuration for at least one Availability Zone."
  }
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "VPC Name cannot be empty"
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
}

# ✅ FIX 5: Industry Standard Tagging Strategy
variable "tags" {
  description = "A map of custom tags to append to all resources"
  type        = map(string)
  default     = {}
}

# ✅ FIX 10: HA NAT per AZ Controls
variable "enable_nat_gateway" {
  description = "Set to true to provision NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Set to true to provision a single shared NAT Gateway across all private networks (Dev/Test). Set to false for a NAT per AZ (Prod)."
  type        = bool
  default     = false
}