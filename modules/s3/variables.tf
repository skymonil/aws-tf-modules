variable "tags" {

  description = "Tags applied to "

  type = map(string)

  default = {}

}

variable "bucket_name" {
  description = "The globally unique name of the S3 bucket"
  type        = string
}


variable "enable_versioning" {
  description = "Enable versioning to protect against overwrites and deletes"
  type        = bool
  default     = true
}

variable "enable_lifecycle_rules" {
  description = "Enable automated cost-optimization lifecycle rules"
  type        = bool
  default     = true
}

variable "transition_to_ia_days" {
  description = "Number of days before moving files to Infrequent Access storage"
  type        = number
  default     = 90
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days before permanently deleting old file versions"
  type        = number
  default     = 30
}