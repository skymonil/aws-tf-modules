## ecs-service/locals.tf
locals {
  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "ecs-service"
    },
    var.tags # Note: Added tags variable to the variables.tf below!
  )

  #  FIX 8: Extract Cluster Name dynamically to avoid passing it twice
  cluster_name = element(split("/", var.service.cluster_arn), 1)

   # Find the primary container's log group name safely
  primary_log_group = values(var.service.containers)[0].log_group_name

  container_environment = [
    for k, v in var.service.container.environment :
    {
      name  = k
      value = v
    }
  ]

  container_secrets = [
    for k, v in var.service.container.secrets :
    {
      name      = k
      valueFrom = v
    }
  ]
}