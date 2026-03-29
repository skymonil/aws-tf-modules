# 1. The Core Bucket
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  # Prevent accidental deletion of the bucket itself via Terraform
  lifecycle {
    prevent_destroy = true
  }

  tags = local.common_tags
}

# 2. Public Access Block (The Leak Preventer)
# This mathematically guarantees that no one can accidentally make a file public.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Versioning (The Ransomware Protection)
# If someone overwrites a file, the original is saved as a hidden version.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# 4. Server-Side Encryption (The Compliance Check)
# Automatically encrypts all data at rest using AWS KMS or AES256.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 5. Lifecycle Policy (The Cost Optimizer)
# Moves old data to cheaper storage, and deletes old versions so versioning doesn't bankrupt you.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  # Only attach this resource if the user enables lifecycle rules
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "auto-archive-and-cleanup"
    status = "Enabled"

    # Move current files to Standard-IA (cheaper) after 90 days
    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    # Delete non-current versions (the hidden files) after 30 days to save money
    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}