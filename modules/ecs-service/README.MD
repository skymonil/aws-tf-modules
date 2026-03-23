This is the final polish on a masterclass module. A well-documented module is the difference between code that only *you* can understand, and code that an entire engineering organization can adopt and scale with.

Because you implemented advanced features like Circuit Breakers, Sidecar-ready container maps, and dynamic autoscaling, this README needs to clearly show downstream developers how powerful and flexible this module is.

Here is the production-grade `README.md` for your `ecs-service` directory.

-----

````markdown
# AWS ECS Fargate Service Module

A production-ready, highly composable Terraform module for deploying microservices to Amazon ECS using AWS Fargate.

This module abstracts away the complexity of ECS Task Definitions, Services, and Application Autoscaling. It uses a strictly typed, object-based data contract to ensure deployments are safe, predictable, and easy to read.

## ✨ Features

* **Sidecar-Ready Architecture:** The `containers` input is a `map(object)`, allowing you to deploy multi-container tasks (e.g., an App container alongside a Datadog agent or Envoy proxy) seamlessly.
* **Native Autoscaling:** Built-in Target Tracking scaling policies for both CPU and Memory.
* **Deployment Safety:** Enforces AWS Deployment Circuit Breakers with automatic rollback capabilities to prevent infinite crash loops on bad image pushes.
* **Dynamic Secrets Injection:** Automatically formats a map of AWS SSM/Secrets Manager ARNs into the exact JSON structure ECS requires for container secrets.
* **Fargate Guardrails:** Built-in Terraform validation to ensure requested Task CPU and Memory configurations match valid AWS Fargate hardware tiers.

---

## 🚀 Usage Example

```hcl
module "payment_api" {
  source = "git::[https://github.com/your-org/terraform-modules.git//ecs-service?ref=v1.0.0](https://github.com/your-org/terraform-modules.git//ecs-service?ref=v1.0.0)"

  tags = {
    Environment = "production"
    Team        = "Payments"
  }

  service = {
    name        = "payment-api"
    cluster_arn = module.ecs_cluster.cluster_arn 

    networking = {
      subnets          = ["subnet-12345a", "subnet-67890b"]
      security_groups  = ["sg-0123456789abcdef"]
      assign_public_ip = false
    }

    task = {
      execution_role_arn = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
      task_role_arn      = "arn:aws:iam::123456789012:role/ecsTaskRole"
      cpu                = 512
      memory             = 1024
    }

    # Map of containers. The key ("api") becomes the container name.
    containers = {
      "api" = {
        image          = "[123456789012.dkr.ecr.ap-south-1.amazonaws.com/payment-api:latest](https://123456789012.dkr.ecr.ap-south-1.amazonaws.com/payment-api:latest)"
        port           = 5000
        log_group_name = "/ecs/prod/payment-api"
        
        environment = {
          NODE_ENV = "production"
          PORT     = "5000"
        }
        secrets = {
          STRIPE_KEY = "arn:aws:ssm:ap-south-1:123456789012:parameter/prod/stripe_key"
        }
      }
    }

    autoscaling = {
      enabled       = true
      min_capacity  = 2
      max_capacity  = 10
      cpu_target    = 70
      memory_target = 75
    }

    deployment = {
      min_healthy_percent      = 100
      max_percent              = 200
      circuit_breaker_enable   = true
      circuit_breaker_rollback = true
    }
  }
}
````

-----

## 📋 Requirements

| Name | Version |
|------|---------|
| \<a name="requirement\_terraform"\>\</a\> [terraform](https://www.google.com/search?q=%23requirement_terraform) | \>= 1.7.0 |
| \<a name="requirement\_aws"\>\</a\> [aws](https://www.google.com/search?q=%23requirement_aws) | \~\> 5.0 |

-----

## 📥 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| \<a name="input\_service"\>\</a\> [service](https://www.google.com/search?q=%23input_service) | The primary configuration object for the ECS Task, Service, Containers, and Autoscaling. | `object({...})` | n/a | yes |
| \<a name="input\_tags"\>\</a\> [tags](https://www.google.com/search?q=%23input_tags) | A map of custom tags to apply to all resources managed by this module. | `map(string)` | `{}` | no |

### The `service` Object Structure

Because the `service` variable is a complex object, here is a breakdown of its expected nested blocks:

  * **`name`** (String) - Name of the service.
  * **`cluster_arn`** (String) - ARN of the target ECS Cluster.
  * **`networking`** (Object) - Requires `subnets`, `security_groups`, and optional `assign_public_ip`.
  * **`task`** (Object) - Requires `cpu`, `memory`, `execution_role_arn`, and `task_role_arn`.
  * **`containers`** (Map of Objects) - Define one or more containers. Supports `image`, `port`, `cpu`, `memory`, `environment` (map), `secrets` (map), and `log_group_name`.
  * **`deployment`** (Object, Optional) - Controls rolling updates and circuit breakers.
  * **`autoscaling`** (Object, Optional) - Controls Target Tracking scaling policies.
  * **`load_balancer`** (Object, Optional) - Requires `target_group_arn`, `container_name`, and `container_port`.

-----

## 📤 Outputs

| Name | Description |
|------|-------------|
| \<a name="output\_service\_name"\>\</a\> [service\_name](https://www.google.com/search?q=%23output_service_name) | The exact name of the deployed ECS Service. |
| \<a name="output\_service\_arn"\>\</a\> [service\_arn](https://www.google.com/search?q=%23output_service_arn) | The Amazon Resource Name (ARN) of the deployed ECS Service. |
| \<a name="output\_task\_definition\_arn"\>\</a\> [task\_definition\_arn](https://www.google.com/search?q=%23output_task_definition_arn) | The ARN of the generated Task Definition. |

