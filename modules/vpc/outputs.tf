output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  description = "Flat list of public subnet IDs"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Flat list of private subnet IDs"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "database_subnet_ids" {
  description = "Flat list of database subnet IDs"
  value       = [for subnet in aws_subnet.database : subnet.id]
}

output "subnets" {
  description = "Rich map of subnets mapped by AZ, containing ID and CIDR blocks"
  value = {
    public = {
      for az, subnet in aws_subnet.public : az => {
        id   = subnet.id
        cidr = subnet.cidr_block
      }
    }
    private = {
      for az, subnet in aws_subnet.private : az => {
        id   = subnet.id
        cidr = subnet.cidr_block
      }
    }
    database = {
      for az, subnet in aws_subnet.database : az => {
        id   = subnet.id
        cidr = subnet.cidr_block
      }
    }
  }
}