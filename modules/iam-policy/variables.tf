variable "policies" {

  description = "Map of IAM policies to create"

  type = map(object({

    description = optional(string)

    policy = any

    path = optional(string, "/")

  }))

}

variable "tags" {

  description = "Tags applied to policies"

  type = map(string)

  default = {}

}