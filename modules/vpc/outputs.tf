output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

# Extracts the IDs from the for_each map into a flat list
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for subnet in aws_subnet.public_subnet : subnet.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for subnet in aws_subnet.private_subnet : subnet.id]
}


# ✅ FIX 12: Richer Outputs Using Maps
output "subnets" {
  description = "A mapped object containing public and private subnet IDs mapped by AZ"
  value = {
    public  = { for k, v in aws_subnet.public_subnet : k => v.id }
    private = { for k, v in aws_subnet.private_subnet : k => v.id }
  }
}