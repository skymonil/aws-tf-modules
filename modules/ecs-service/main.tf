## ecs-service/main.tf
data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  count = var.service.container.log_group_name != null ? 1 : 0

  name              = var.service.container.log_group_name
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.service.name
  cpu                      = var.service.task.cpu
  memory                   = var.service.task.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  #  CPU/Memory locked to the Task level


  execution_role_arn = var.service.task.execution_role_arn
  task_role_arn      = var.service.task.task_role_arn

  container_definitions = jsonencode([
    for container_name, config in var.service.containers : {
      name      = var.service.container.name
      image     = var.service.container.image
      cpu       = var.service.container.cpu
      memory    = var.service.container.memory
      essential = true

      portMappings = config.port != null ? [
        {
          containerPort = config.port
          protocol      = "tcp"
        }
      ] : []

      environment = [for k, v in config.environment : { name = k, value = v }]
      secrets     = [for k, v in config.secrets : { name = k, valueFrom = v }]

      logConfiguration = config.log_group_name != null ? {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = config.log_group_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = container_name
        }
      } : null
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "this" {
  name             = var.service.name
  cluster          = var.service.cluster_arn
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.service.autoscaling.min_capacity
  platform_version = var.service.task.platform_version

  #  Deployment configuration
  deployment_minimum_healthy_percent = var.service.deployment.min_healthy_percent
  deployment_maximum_percent         = var.service.deployment.max_percent

  #  Exec and Grace Period
  enable_execute_command            = var.service.enable_execute_command
  health_check_grace_period_seconds = var.service.load_balancer != null ? var.service.health_check_grace_period_seconds : 0

  #  Circuit Breaker
  deployment_circuit_breaker {
    enable   = var.service.deployment.circuit_breaker_enable
    rollback = var.service.deployment.circuit_breaker_rollback
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.service.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = try(capacity_provider_strategy.value.base, null)
    }
  }

  network_configuration {
    subnets          = var.service.networking.subnets
    security_groups  = var.service.networking.security_groups
    assign_public_ip = var.service.networking.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.service.load_balancer != null ? [var.service.load_balancer] : []
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = var.service.container.name
      container_port   = load_balancer.value.container_port
    }
  }



  # NOTE: Ignoring task_definition is standard IF your CI/CD pipeline (like GitHub Actions) 
  # is responsible for deploying new images. If Terraform manages image versions, remove this.
  lifecycle {
    ignore_changes = [task_definition, desired_count] # Also ignore desired_count so autoscaling doesn't reset!
  }

  tags = local.common_tags
}

# --- AUTOSCALING ---
resource "aws_appautoscaling_target" "this" {
  for_each = var.service.autoscaling.enabled ? { main = true } : {}

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"

  # Safer string interpolation by relying on the cluster name rather than splitting an ARN
  resource_id = "service/${var.cluster_name}/${aws_ecs_service.this.name}"

  min_capacity = var.service.autoscaling.min_capacity
  max_capacity = var.service.autoscaling.max_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = var.service.autoscaling.enabled ? { main = true } : {}

  name               = "${var.service.name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this["main"].resource_id
  scalable_dimension = aws_appautoscaling_target.this["main"].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this["main"].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.service.autoscaling.cpu_target
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "memory" {
  for_each = var.service.autoscaling.enabled ? { main = true } : {}

  name               = "${var.service.name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this["main"].resource_id
  scalable_dimension = aws_appautoscaling_target.this["main"].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this["main"].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.service.autoscaling.memory_target
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}