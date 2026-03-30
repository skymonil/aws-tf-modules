Here is the production-ready `README.md` for your enterprise VPC module. It highlights the advanced architectural decisions, feature toggles, and strict security compliance measures you have implemented.

---

# AWS Enterprise VPC Terraform Module

A highly flexible, secure, and production-ready Terraform module for provisioning a modern AWS Virtual Private Cloud (VPC).

This module replaces fragile, index-based lists with a strictly typed **map-based subnet configuration**. It natively supports both 2-tier (startup/dev) and 3-tier (enterprise/prod) architectures, complete with advanced security baselines and cost-optimization features built-in.

---

## ✨ Enterprise Features

* **Dynamic 3-Tier Architecture:** Easily provision Public, Private, and Database (Isolated) subnets. The database tier is fully optional, allowing the same module to power both lightweight Dev environments and highly regulated Production environments.
* **Consolidated Feature Toggles:** Toggle NAT Gateways (HA vs. Single), VPC Endpoints, Flow Logs, and NACLs via a single, clean `features` object.
* **Security & Compliance First:** 
  * Automatically neutralizes the Default VPC Security Group to pass SOC2/PCI-DSS audits.
  * Optionally provisions strict, subnet-level Network ACLs (NACLs).
  * Automates VPC Flow Logs to CloudWatch for comprehensive network auditing.
* **Cost Optimization (PrivateLink):** Automatically provisions S3 Gateway and ECR Interface endpoints to keep AWS API traffic off your expensive NAT Gateways.
* **Rich Mapped Outputs:** Exports a structured object containing subnet IDs and CIDRs strictly mapped by Availability Zone (AZ), making downstream EKS, ECS, and RDS configurations perfectly deterministic.

---

## 🚀 Usage Examples

### 1. Production (3-Tier, High Availability, High Security)

This configuration deploys a highly available infrastructure with a database tier, a NAT Gateway in every AZ, VPC Endpoints, and full audit logging.

```hcl
module "vpc_prod" {
  source = "../../modules/vpc"

  vpc_name       = "dronapay-prod-vpc"
  environment    = "prod"
  region         = "ap-south-1"
  vpc_cidr_block = "10.0.0.0/16"

  # All enterprise features enabled
  features = {
    nat_gateway        = true
    single_nat_gateway = false # HA NAT
    flow_logs          = true
    vpc_endpoints      = true
    nacl               = true
  }

  subnet_config = {
    "ap-south-1a" = {
      public_cidr  = "10.0.1.0/24"
      private_cidr = "10.0.11.0/24"
    }
    "ap-south-1b" = {
      public_cidr  = "10.0.2.0/24"
      private_cidr = "10.0.12.0/24"
    }
  }

  database_subnet_config = {
    "ap-south-1a" = { database_cidr = "10.0.21.0/24" }
    "ap-south-1b" = { database_cidr = "10.0.22.0/24" }
  }

  tags = {
    Project = "DronaPay"
  }
}
```

### 2. Staging / Development (2-Tier, Cost-Optimized)

This configuration deploys a lightweight infrastructure with shared NATs, no isolated DB tier, and disables expensive endpoints for cost savings.

```hcl
module "vpc_staging" {
  source = "../../modules/vpc"

  vpc_name       = "dronapay-staging-vpc"
  environment    = "staging"
  region         = "ap-south-1"
  vpc_cidr_block = "10.1.0.0/16"

  # Cost-saving toggles
  features = {
    nat_gateway        = true
    single_nat_gateway = true  # 1 shared NAT for all AZs
    flow_logs          = false # Save CloudWatch costs
    vpc_endpoints      = false # Save PrivateLink costs
    nacl               = false
  }

  subnet_config = {
    "ap-south-1a" = {
      public_cidr  = "10.1.1.0/24"
      private_cidr = "10.1.11.0/24"
    }
  }
}
```

---

## 📥 Inputs

| Name | Description | Type | Default | Required |
| :--- | :--- | :--- | :--- | :---: |
| `vpc_name` | Name prefix for the VPC and related resources | `string` | n/a | **yes** |
| `environment` | Deployment environment (e.g. dev, staging, prod) | `string` | n/a | **yes** |
| `region` | AWS Region for endpoint deployment | `string` | n/a | **yes** |
| `vpc_cidr_block` | Primary CIDR block for the VPC | `string` | n/a | **yes** |
| `subnet_config` | Map of AZ keys to public/private CIDR blocks | `map(object)` | n/a | **yes** |
| `database_subnet_config` | Optional map of AZ keys to database CIDR blocks | `map(object)` | `{}` | no |
| `features` | Object to toggle NAT, Flow Logs, Endpoints, and NACLs | `object` | *(see below)* | no |
| `tags` | Custom map of tags to append to all resources | `map(string)` | `{}` | no |

### Default `features` Object
```hcl
{
  nat_gateway        = true
  single_nat_gateway = false
  flow_logs          = true
  vpc_endpoints      = true
  nacl               = true
}
```

---

## 📤 Outputs

| Name | Description |
| :--- | :--- |
| `vpc_id` | The ID of the VPC. |
| `public_subnet_ids` | Flat list of public subnet IDs. |
| `private_subnet_ids` | Flat list of private subnet IDs. |
| `database_subnet_ids` | Flat list of database subnet IDs. |
| `subnets` | Rich mapped object containing `public`, `private`, and `database` subnets mapped securely by AZ. |

### Output Example (`subnets`)
Downstream modules can confidently target specific AZs using this structure:
```json
{
  "private": {
    "ap-south-1a": {
      "id": "subnet-0abcd1234efgh5678",
      "cidr": "10.0.11.0/24"
    }
  }
}
```