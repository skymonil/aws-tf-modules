To complete your module library, this `README.md` for the `ecs-cluster` module is designed to be clean, concise, and professional. It highlights the use of **Capacity Providers**, which is a high-value feature for production environments (especially when mixing Fargate and Fargate Spot to save costs).

-----

````markdown
# AWS ECS Cluster Module

A lightweight, production-ready Terraform module to provision an Amazon ECS (Elastic Container Service) Cluster.

This module focuses on the "Platform" layer of your infrastructure. It handles the logical cluster grouping, CloudWatch Container Insights for monitoring, and the configuration of Capacity Providers (Fargate/Fargate Spot).

## ✨ Features

* **Container Insights:** Easily toggle CloudWatch Container Insights for deep visibility into task-level CPU, memory, and network usage.
* **Flexible Capacity Strategies:** Support for multiple capacity providers and default strategies (e.g., splitting traffic between Fargate and Fargate Spot for cost optimization).
* **Dynamic Provider Mapping:** Uses `dynamic` blocks to safely handle complex capacity provider configurations.
* **Standardized Tagging:** Merges global tags with resource-specific naming conventions.

---

## 🚀 Usage Example

### Basic Fargate Cluster
```hcl
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  name                      = "prod-core-cluster"
  enable_container_insights = true

  tags = {
    Environment = "production"
    Department  = "Platform-Engineering"
  }
}
````

### Cost-Optimized Cluster (Fargate + Fargate Spot)

This configuration uses **Fargate Spot** for 80% of the weight to significantly reduce AWS bills.

```hcl
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  name               = "dev-cluster"
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 20
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 80
    }
  ]
}
```

-----

## 📋 Requirements

| Name | Version |
|------|---------|
| \<a name="requirement\_terraform"\>\</a\> [terraform](https://www.google.com/search?q=%23requirement_terraform) | \>= 1.5.0 |
| \<a name="requirement\_aws"\>\</a\> [aws](https://www.google.com/search?q=%23requirement_aws) | \~\> 5.0 |

-----

## 📥 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| \<a name="input\_name"\>\</a\> [name](https://www.google.com/search?q=%23input_name) | The name of the ECS Cluster | `string` | n/a | yes |
| \<a name="input\_enable\_container\_insights"\>\</a\> [enable\_container\_insights](https://www.google.com/search?q=%23input_enable_container_insights) | Enable CloudWatch container insights for the cluster | `bool` | `true` | no |
| \<a name="input\_capacity\_providers"\>\</a\> [capacity\_providers](https://www.google.com/search?q=%23input_capacity_providers) | List of capacity providers to associate with the cluster | `list(string)` | `["FARGATE"]` | no |
| \<a name="input\_default\_capacity\_provider\_strategy"\>\</a\> [default\_capacity\_provider\_strategy](https://www.google.com/search?q=%23input_default_capacity_provider_strategy) | Default strategy for distributing tasks across providers | `list(object)` | `[FARGATE (Weight 1)]` | no |
| \<a name="input\_tags"\>\</a\> [tags](https://www.google.com/search?q=%23input_tags) | Common tags to be applied to the cluster | `map(string)` | `{}` | no |

-----

## 📤 Outputs

| Name | Description |
|------|-------------|
| \<a name="output\_cluster\_arn"\>\</a\> [cluster\_arn](https://www.google.com/search?q=%23output_cluster_arn) | The Amazon Resource Name (ARN) that identifies the cluster. |
| \<a name="output\_cluster\_name"\>\</a\> [cluster\_name](https://www.google.com/search?q=%23output_cluster_name) | The name of the ECS Cluster (useful for service discovery). |
| \<a name="output\_cluster\_id"\>\</a\> [cluster\_id](https://www.google.com/search?q=%23output_cluster_id) | The ID of the ECS Cluster. |


