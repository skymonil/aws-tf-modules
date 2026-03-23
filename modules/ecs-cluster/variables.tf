variable "name" {
  description = "Cluster name"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch container insights"
  type        = bool
  default     = true
}

variable "capacity_providers" {
  description = "Capacity providers for ECS cluster"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))

  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
    }
  ]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}