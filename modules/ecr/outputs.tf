output "repo_arn" {
  description = "cluster ARN"
  value       = aws_ecr_repostory.this.arn
}


output "repo_id" {
  description = "Cluster ID"
  value       = aws_ecr_repostory.this.id
}

output "repo_name" {
  description = "Repo Name"
  value       = aws_ecr_repostory.this.name
}


output "repository_url" {
  description = "The URL of the ECR repository (used for docker push)"
  value       = aws_ecr_repository.this.repository_url
}
