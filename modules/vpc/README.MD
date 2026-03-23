This `README.md` is designed to showcase the high-level architecture decisions you made, specifically the **Map-Based Subnetting** and the **Dynamic NAT Gateway** logic. This level of documentation is exactly what a hiring manager at a company like Drona Pay looks for.

-----

````markdown
# AWS Production VPC Module

A highly flexible and robust Terraform module for provisioning a multi-tier AWS Virtual Private Cloud (VPC). 

This module moves away from fragile index-based lists and uses a **strictly typed Map-Based configuration**. This ensures that Availability Zones (AZs) and their respective CIDR blocks are always perfectly aligned, eliminating the risk of "Index Shifts" during infrastructure updates.

## ✨ Features

* **Map-Based Subnetting:** Uses a `map(object)` to define subnets, making the relationship between AZs and CIDR blocks explicit and unbreakable.
* **Dynamic NAT Topologies:** * `single_nat_gateway = true`: Deploys one NAT Gateway for the entire VPC (Ideal for cost-saving in Dev/Staging).
  * `single_nat_gateway = false`: Deploys a NAT Gateway per AZ (High Availability for Production).
* **Automatic AZ Discovery:** Dynamically extracts and sorts Availability Zones from the input map keys to maintain state consistency.
* **Modern Routing:** Decouples route tables from routes to allow for "NAT-less" private subnets without breaking Terraform associations.
* **Rich Outputs:** Exports subnets as AZ-mapped objects, allowing downstream modules (like EKS or RDS) to pick specific subnets by AZ name.
* **Standardized Tagging:** Automatically merges global tags with resource-specific naming conventions.

---

## 🚀 Usage Example

### Production Configuration (High Availability)
```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = "dronapay-prod-vpc"
  environment        = "prod"
  region             = "ap-south-1"
  vpc_cidr_block     = "10.0.0.0/16"
  
  single_nat_gateway = false # NAT per AZ
  enable_nat_gateway = true

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
}
````

-----

## 📋 Requirements

| Name | Version |
|------|---------|
| \<a name="requirement\_terraform"\>\</a\> [terraform](https://www.google.com/search?q=%23requirement_terraform) | \>= 1.5.0 |
| \<a name="requirement\_aws"\>\</a\> [aws](https://www.google.com/search?q=%23requirement_aws) | \~\> 5.0 |

-----

## 📥 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| \<a name="input\_vpc\_cidr\_block"\>\</a\> [vpc\_cidr\_block](https://www.google.com/search?q=%23input_vpc_cidr_block) | CIDR for the VPC (Validation: must be /24 or smaller) | `string` | n/a | yes |
| \<a name="input\_subnet\_config"\>\</a\> [subnet\_config](https://www.google.com/search?q=%23input_subnet_config) | Map of AZ keys to public/private CIDR objects | `map(object)` | n/a | yes |
| \<a name="input\_vpc\_name"\>\</a\> [vpc\_name](https://www.google.com/search?q=%23input_vpc_name) | Name prefix for all resources | `string` | n/a | yes |
| \<a name="input\_single\_nat\_gateway"\>\</a\> [single\_nat\_gateway](https://www.google.com/search?q=%23input_single_nat_gateway) | If true, all private subnets share a single NAT | `bool` | `false` | no |
| \<a name="input\_enable\_nat\_gateway"\>\</a\> [enable\_nat\_gateway](https://www.google.com/search?q=%23input_enable_nat_gateway) | Toggle for NAT Gateway provisioning | `bool` | `true` | no |
| \<a name="input\_tags"\>\</a\> [tags](https://www.google.com/search?q=%23input_tags) | Map of extra tags to apply to resources | `map(string)` | `{}` | no |

-----

## 📤 Outputs

| Name | Description |
|------|-------------|
| \<a name="output\_vpc\_id"\>\</a\> [vpc\_id](https://www.google.com/search?q=%23output_vpc_id) | The ID of the VPC. |
| \<a name="output\_subnets"\>\</a\> [subnets](https://www.google.com/search?q=%23output_subnets) | A rich map containing `public` and `private` keys, each holding a map of AZ-to-SubnetID. |
| \<a name="output\_private\_subnet\_ids"\>\</a\> [private\_subnet\_ids](https://www.google.com/search?q=%23output_private_subnet_ids) | A flat list of private subnet IDs for easy consumption. |

-----

## 🛠️ Design Note: Sorting AZs

This module uses `sort(keys(var.subnet_config))` within its locals. This is a critical safety feature. Because maps in HCL are unordered, sorting the keys ensures that if you use `single_nat_gateway`, Terraform always picks the same AZ (alphabetically first) to host the gateway, preventing unnecessary "destroy and recreate" cycles on your NAT EIPs.

```

***

```