

variable "role_name" {

  description = "Name of IAM role"

  type = string

}

variable "policy_arns" {

  description = "List of policy ARNs to attach"

  type = list(string)

}

variable "tags" {

  description = "Tags applied to policies"

  type = map(string)

  default = {}

}