This completes your core documentation library. This Security Group module is particularly high-value because of its **Dynamic Block** implementation—it allows you to manage dozens of rules without writing a single redundant resource block.

-----

````markdown
# AWS Security Group Module

A highly flexible, dynamic Terraform module for managing AWS Security Groups. 

Unlike standard modules that require separate resources for CIDR-based rules and Security-Group-based rules, this module uses **Dynamic Blocks** and **Optional Attributes** to handle all rule types within a single, elegant data structure.

## ✨ Features

* **Unified Rule Engine:** Manage both `cidr_blocks` and `source_security_group_id` rules within the same map.
* **Dynamic Blocks:** Automatically generates `ingress` and `egress` blocks based on the provided configuration, keeping your code DRY.
* **Intelligent Defaults:** Egress is pre-configured to allow all outbound traffic by default, but remains fully customizable.
* **VPC Agnostic:** Designed to be injected with any VPC ID, making it ideal for multi-VPC or peering architectures.
* **Clean Logic:** Uses conditional logic to ensure only the necessary rule attributes (CIDR vs. Source ID) are applied to the AWS API.

---

## 🚀 Usage

### Simple CIDR-Based Rules (Public ALB)
```hcl
module "alb_sg" {
  source = "../../modules/security-group"

  sg_name = "web-lb-sg"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = {
    "http" = {
      description = "Public HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
````

### Source-Group-Based Rules (Private App Tier)

This example restricts traffic so that the App Tier **only** accepts traffic coming from the Load Balancer.

```hcl
module "app_sg" {
  source = "../../modules/security-group"

  sg_name = "app-tier-sg"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = {
    "alb_traffic" = {
      description              = "Traffic from ALB only"
      from_port                = 5000
      to_port                  = 5000
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
    }
  }
}
```

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
| \<a name="input\_sg\_name"\>\</a\> [sg\_name](https://www.google.com/search?q=%23input_sg_name) | Name of the Security Group | `string` | n/a | yes |
| \<a name="input\_vpc\_id"\>\</a\> [vpc\_id](https://www.google.com/search?q=%23input_vpc_id) | The VPC ID where the SG will be created | `string` | n/a | yes |
| \<a name="input\_sg\_description"\>\</a\> [sg\_description](https://www.google.com/search?q=%23input_sg_description) | Description for the Security Group | `string` | `"Managed by Terraform"` | no |
| \<a name="input\_ingress\_rules"\>\</a\> [ingress\_rules](https://www.google.com/search?q=%23input_ingress_rules) | Map of ingress rule objects | `map(object)` | `{}` | no |
| \<a name="input\_egress\_rules"\>\</a\> [egress\_rules](https://www.google.com/search?q=%23input_egress_rules) | Map of egress rule objects | `map(object)` | `{0.0.0.0/0 open}` | no |
| \<a name="input\_tags"\>\</a\> [tags](https://www.google.com/search?q=%23input_tags) | Custom tags for the resource | `map(string)` | `{}` | no |

-----

## 📤 Outputs

| Name | Description |
|------|-------------|
| \<a name="output\_security\_group\_id"\>\</a\> [security\_group\_id](https://www.google.com/search?q=%23output_security_group_id) | The ID of the created Security Group. |

```

---


```