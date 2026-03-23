# envs/prod/providers.tf

terraform {
  # 1. Always pin your Terraform core version
  required_version = ">= 1.5.0" 

  # 2. Pin your provider versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 3. The Remote Backend Configuration
 backend "s3" {
    bucket       = "educore-tf-state"
    key          = "prod/educore.tfstate"
    region       = "ap-south-1"
    
    # ✅ Enable S3-native locking (No DynamoDB needed)
    use_lockfile = true 
    
    encrypt      = true
  }
}

# 4. Configure the AWS Provider
provider "aws" {
  region = var.region

  # PRO TIP: You can set global tags here that apply to EVERY resource automatically!
  default_tags {
    tags = {
      DeploymentMethod = "Terraform"
      Repository       = "core-infrastructure"
    }
  }
}