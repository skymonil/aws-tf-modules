## ecs-service/variables.tf
variable "tags" {
  description = "Custom tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "service" {

  description = "ECS service configuration"

  type = object({

    name = string

    cluster_arn = string

    networking = object({

      subnets          = list(string)
      security_groups  = list(string)
      assign_public_ip = optional(bool, false)

    })

    task = object({

      execution_role_arn = string
      task_role_arn      = string
      cpu                = number
      memory             = number
      platform_version   = optional(string, "LATEST")

    })

    #  Deployment controls and Circuit Breaker
    deployment = optional(object({
      min_healthy_percent      = optional(number, 100)
      max_percent              = optional(number, 200)
      circuit_breaker_enable   = optional(bool, true)
      circuit_breaker_rollback = optional(bool, true)
    }), {})


    containers = map(object({
      image          = string
      port           = optional(number)
      cpu            = optional(number) # Optional at container level
      memory         = optional(number) # Optional at container level
      environment    = optional(map(string), {})
      secrets        = optional(map(string), {})
      log_group_name = optional(string)
    }))

    logging = optional(object({
      create_log_group   = optional(bool, true)
      log_retention_days = optional(number, 7)
    }), {})

    load_balancer = optional(object({

      target_group_arn = string
      container_name   = string # Must match a key in the containers map
      container_port   = number

    }))

    autoscaling = optional(object({

      enabled = optional(bool, false)
      min_capacity = optional(number, 1)
      max_capacity = optional(number, 2)
      cpu_target    = optional(number, 70)
      memory_target = optional(number, 75)

    }))

    capacity_provider_strategy = optional(list(object({

      capacity_provider = string
      weight            = number
      base              = optional(number)

      })), [

      {
        capacity_provider = "FARGATE"
        weight            = 1
      }

    ])
    enable_execute_command            = optional(bool, false)
    health_check_grace_period_seconds = optional(number, 0)
  })

  # AWS Fargate strictly enforces these CPU values
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096, 8192, 16384], var.service.task.cpu)
    error_message = "Task CPU must be a valid Fargate size (256, 512, 1024, 2048, 4096, 8192, 16384)."
  }

}

variable "cluster_name" {
  description = "The plaintext name of the ECS cluster (used for autoscaling resource IDs)"
  type        = string
}

variable "tags" {
  description = "Custom tags to apply to all resources"
  type        = map(string)
  default     = {}
}