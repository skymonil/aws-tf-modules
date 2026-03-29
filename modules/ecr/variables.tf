

variable "tags" {
  description = "Tags applied to ecr Repository"

  type = map(string)

  default = {}
}

variable "repo_name" {
  description = "ECR Repository name"
  type        = string

}


variable "ecr_image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"

  # The Condition: Terraform will throw an error if someone tries to input a typo
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "The image_tag_mutability variable must be either 'MUTABLE' or 'IMMUTABLE'."
  }
}