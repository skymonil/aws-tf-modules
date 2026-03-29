Here is the complete, production-ready `README.md` for your S3 module. It is structured exactly how senior DevOps engineers expect to see documentation: a clear usage example, a breakdown of the variables, and a concrete architectural guide on when to toggle specific features.

***

```markdown
# Terraform Module: Production-Grade Secure S3 Bucket

This module provisions an AWS S3 bucket architected for enterprise production environments. By default, it enforces strict security boundaries, protects against accidental data deletion, and prevents public data exposure.

## Features

* **Default Deny Public Access:** Automatically attaches a Public Access Block (PAB) to prevent ACLs or bucket policies from exposing data to the internet.
* **Accidental Deletion Protection:** Utilizes Terraform's `prevent_destroy` lifecycle rule to prevent the bucket from being destroyed via IaC.
* **Automated Data Protection:** Natively supports bucket versioning to protect against application overwrites and ransomware.
* **Cost Optimization:** Built-in lifecycle rules to transition cold data to cheaper storage tiers and automatically prune old versions.
* **Encryption at Rest:** Enforces AES256 server-side encryption by default.

## Usage

```hcl
module "secure_documents_bucket" {
  source = "./modules/s3-secure-bucket"

  bucket_name = "my-company-secure-documents-prod"

  # Feature Toggles
  enable_versioning      = true
  enable_lifecycle_rules = true

  # Cost Optimization Tuning
  transition_to_ia_days              = 90
  noncurrent_version_expiration_days = 30

  tags = {
    Environment = "Production"
    Owner       = "Platform-Team"
  }
}
```

---

## Architectural Guide: When to Enable Specific Features

This module is designed to be flexible. Not every bucket needs every feature. Use the following guide to determine the correct configuration for your workload.

### `enable_versioning`
* **When to enable (`true`):** 
  * **Terraform State Files:** Absolutely mandatory. If a state file is corrupted, you must be able to roll back.
  * **User Uploads/Documents:** If users are uploading documents that might be accidentally overwritten by another user with the same filename.
  * **Compliance Data:** If audit regulations require you to maintain a strict history of file modifications.
* **When to disable (`false`):** 
  * **Temporary Logs & Scratch Spaces:** If the bucket is just holding temporary application logs, ETL scratch data, or CI/CD build artifacts that are deleted shortly after creation, versioning just doubles your AWS bill for no reason.
  * **Static Website Assets:** If you are fronting the bucket with CloudFront, you usually invalidate the CDN cache rather than needing strict version history in S3.

### `enable_lifecycle_rules`
* **When to enable (`true`):** 
  * **Buckets with Versioning Enabled:** If you turn on versioning, you *must* turn on lifecycle rules. Otherwise, the hidden `noncurrent` versions of files will accumulate forever and bankrupt you.
  * **Data Lakes & Archival:** If you are storing database backups, historical logs, or analytics data that is rarely accessed after the first few months. The module will automatically push this data to `STANDARD_IA` (Infrequent Access) to cut costs by roughly 50%.
* **When to disable (`false`):** 
  * **Short-Lived Dev/Test Buckets:** If the entire bucket is going to be destroyed at the end of the week.
  * **High-Frequency Access Data:** If the data in the bucket will be actively read every single day for years. Transitioning to `STANDARD_IA` incurs a retrieval fee; if you constantly read `IA` data, it will actually cost *more* than keeping it in standard storage.

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bucket_name` | The globally unique name of the S3 bucket | `string` | n/a | **yes** |
| `enable_versioning` | Enable versioning to protect against overwrites | `bool` | `true` | no |
| `enable_lifecycle_rules` | Enable automated cost-optimization lifecycle rules | `bool` | `true` | no |
| `transition_to_ia_days` | Days before moving files to Infrequent Access storage | `number` | `90` | no |
| `noncurrent_version_expiration_days`| Days before permanently deleting old file versions | `number` | `30` | no |
| `tags` | Additional tags to merge with common_tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | The name of the bucket |
| `bucket_arn` | The ARN of the bucket (Required for IAM policies) |
| `bucket_regional_domain_name` | The bucket region-specific domain name (Required for CloudFront) |

```