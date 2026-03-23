output "cluster_id" {
  description = "Cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "Cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Cluster name"
  value       = aws_ecs_cluster.this.name
}