# AWS Production VPC Terraform Module

A flexible and production-ready Terraform module for provisioning a multi-tier AWS Virtual Private Cloud (VPC).

This module avoids fragile index-based subnet configuration and instead uses a **map-based subnet design**, ensuring Availability Zones (AZs) and CIDR blocks always remain correctly aligned.

The module supports both **cost-optimized startup deployments** and **highly available production architectures** through configurable NAT topology.

---

## Key Features

### Map-Based Subnet Configuration
Subnets are defined using a structured map instead of lists, eliminating index mismatch errors and improving readability.

### Flexible NAT Gateway Topology
Supports both startup-friendly and production-grade network architecture:

* `single_nat_gateway = true`
  * One NAT Gateway shared across all AZs
  * Lower cost
  * Suitable for dev or staging

* `single_nat_gateway = false`
  * One NAT Gateway per AZ
  * High availability
  * Production-ready architecture

### Deterministic AZ Ordering
Uses sorted AZ keys internally to ensure stable Terraform state and prevent unnecessary resource recreation.

### Decoupled Route Tables
Route tables and routes are defined independently, enabling private subnets to exist with or without NAT gateways.

### Rich Outputs
Exports subnet IDs as structured maps keyed by AZ, allowing downstream modules (EKS, ECS, RDS) to reference specific subnets easily.

### Standardized Tagging
Automatically merges global tags with resource-specific naming conventions.

---

## Architecture

Example architecture created by this module:


---

## Usage Example

### Production Configuration (Multi-AZ HA)

```hcl
module "vpc" {

  source = "../../modules/vpc"

  vpc_name       = "educore-prod-vpc"
  vpc_cidr_block = "10.0.0.0/16"

  enable_nat_gateway = true
  single_nat_gateway = false

  subnet_config = {

    ap-south-1a = {
      public_cidr  = "10.0.1.0/24"
      private_cidr = "10.0.11.0/24"
    }

    ap-south-1b = {
      public_cidr  = "10.0.2.0/24"
      private_cidr = "10.0.12.0/24"
    }

  }

  tags = {
    Project     = "educore"
    Environment = "prod"
  }

}

````

Config For Sartups

```hcl
module "vpc" {

  source = "../../modules/vpc"

  vpc_name       = "educore-dev-vpc"
  vpc_cidr_block = "10.1.0.0/16"

  enable_nat_gateway = true
  single_nat_gateway = true

  subnet_config = {

    ap-south-1a = {
      public_cidr  = "10.1.1.0/24"
      private_cidr = "10.1.11.0/24"
    }

  }

}
````
### Inputs

| Name               | Description               | Type        | Required |
| ------------------ | ------------------------- | ----------- | -------- |
| vpc_name           | Name prefix for resources | string      | yes      |
| vpc_cidr_block     | CIDR block for VPC        | string      | yes      |
| subnet_config      | Map of AZ to subnet CIDRs | map(object) | yes      |
| enable_nat_gateway | Enable NAT gateway        | bool        | no       |
| single_nat_gateway | Use one NAT for all AZs   | bool        | no       |
| tags               | Additional resource tags  | map(string) | no       |

subnet_config = {

  ap-south-1a = {

    public_cidr  = string
    private_cidr = string

  }

}

### Outputs

| Name               | Description                     |
| ------------------ | ------------------------------- |
| vpc_id             | ID of the VPC                   |
| public_subnets     | map of AZ to public subnet IDs  |
| private_subnets    | map of AZ to private subnet IDs |
| private_subnet_ids | list of private subnet IDs      |
