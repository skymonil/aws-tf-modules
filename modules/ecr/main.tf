
resource "aws_ecr_repostory" "this" {
  name                 = var.repo_name
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags

}

resource "aws_ecr_lifecycle_policy" "this" {
  # This targets the repository we created in main.tf
  repository = aws_ecr_repository.this.name

  # The JSON rules engine
  policy = jsonencode({
    rules = [
      {
        rulePriority = 10
        description  = "Keep the last 50 production release images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-", "release-", "v"]
          countType     = "imageCountMoreThan"
          countNumber   = 50
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 20
        description  = "Keep the last 10 development/PR images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-", "pr-", "staging-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 30
        description  = "Delete untagged (orphaned) images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}