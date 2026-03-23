variable "subnet_config" {
  description = "A map mapping Availability Zones to their public and private CIDR configurations."
  
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))

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