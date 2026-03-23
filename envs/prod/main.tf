# envs/prod/main.tf

module "vpc" {
  # 1. Point to where the child module lives locally
  source = "../../modules/vpc"

  # 2. Pass in the variables required by the module
  vpc_name           = var.vpc_name
  environment        = var.environment
  region             = var.region
  vpc_cidr_block     = var.vpc_cidr_block
  
  # Because this is PROD, we want High Availability (1 NAT per AZ)
  single_nat_gateway = false
  enable_nat_gateway = true

  # Pass the complex object map
  subnet_config      = var.subnet_config

  # Add any extra tags specific to this environment
  tags = {
    CostCenter = "Infrastructure"
    Critical   = "True"
  }
}