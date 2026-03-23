# modules/security-group/variables.tf

variable "sg_name" {
  description = "Name of the security group"
  type        = string
}

variable "sg_description" {
  description = "Description of the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "ingress_rules" {
  description = "Map of ingress rules. Can use CIDRs or Source SG IDs."
  type = map(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), []) # Defaults to empty list if omitted
    source_security_group_id = optional(string, null)     # Defaults to null if omitted
  }))
  default = {}
}

variable "egress_rules" {
  description = "Map of egress rules"
  type = map(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), ["0.0.0.0/0"]) # Default open outbound
    source_security_group_id = optional(string, null)
  }))
  default = {}
}

variable "tags" {
  description = "Custom tags"
  type        = map(string)
  default     = {}
}