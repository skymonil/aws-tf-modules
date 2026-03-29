variable "role" {

  description = "IAM role configuration"

  type = object({

    name = string

    description = optional(string)

    assume_role_policy = any

    path = optional(string, "/")

    max_session_duration = optional(number, 3600)

    managed_policy_arns = optional(list(string), [])

    inline_policies = optional(map(object({

      description = optional(string)

      policy = any

    })), {})

  })

}

variable "tags" {

  description = "Tags applied to role and policies"

  type = map(string)

  default = {}

}