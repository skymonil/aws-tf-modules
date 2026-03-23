# modules/security-group/main.tf

locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })
}

resource "aws_security_group" "this" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  # --- INGRESS RULES ---
  dynamic "ingress" {
    for_each = var.ingress_rules
    
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      
      # If the list has items, use it. Otherwise, set to null.
      cidr_blocks     = length(ingress.value.cidr_blocks) > 0 ? ingress.value.cidr_blocks : null
      
      # If a source SG ID was provided, wrap it in a list. Otherwise, set to null.
      security_groups = ingress.value.source_security_group_id != null ? [ingress.value.source_security_group_id] : null
    }
  }

  # --- EGRESS RULES ---
  dynamic "egress" {
    for_each = var.egress_rules
    
    content {
      description     = egress.value.description
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = length(egress.value.cidr_blocks) > 0 ? egress.value.cidr_blocks : null
      security_groups = egress.value.source_security_group_id != null ? [egress.value.source_security_group_id] : null
    }
  }

  tags = merge(local.common_tags, { Name = var.sg_name })
}