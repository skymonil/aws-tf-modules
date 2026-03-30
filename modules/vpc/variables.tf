##############################################
# Core Configuration
##############################################

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

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "tags" {
  description = "A map of custom tags to append to all resources"
  type        = map(string)
  default     = {}
}

##############################################
# Network Configuration
##############################################

variable "vpc_cidr_block" {
  type        = string
  description = "Primary CIDR block for the VPC"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block)) && tonumber(split("/", var.vpc_cidr_block)[1]) <= 24
    error_message = "Must be a valid CIDR block with a mask of /24 or smaller (e.g., /24, /23, /22, etc.)."
  }
}

variable "subnet_config" {
  description = "A map mapping Availability Zones to their public and private CIDR configurations."
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))

  validation {
    condition = alltrue([
      for az, config in var.subnet_config :
      can(cidrnetmask(config.public_cidr)) &&
      can(cidrnetmask(config.private_cidr))
    ])
    error_message = "Invalid CIDR format in subnet_config."
  }
}

variable "database_subnet_config" {
  description = "Optional database subnet CIDRs mapped by AZ"
  type = map(object({
    database_cidr = string
  }))
  default = {}
}

##############################################
# Feature Toggles
##############################################

variable "features" {
  description = "Feature toggles for VPC capabilities"
  type = object({
    nat_gateway        = bool
    single_nat_gateway = bool
    flow_logs          = bool
    vpc_endpoints      = bool
    nacl               = bool
  })

  default = {
    nat_gateway        = true
    single_nat_gateway = false
    flow_logs          = true
    vpc_endpoints      = true
    nacl               = true
  }
}