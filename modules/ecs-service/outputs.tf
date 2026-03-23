## ecs-service/outputs.tf
output "service_name" {

  value = aws_ecs_service.this.name
}

output "service_arn" {

  value = aws_ecs_service.this.arn
}

output "task_definition_arn" {

  value = aws_ecs_task_definition.this.arn
}