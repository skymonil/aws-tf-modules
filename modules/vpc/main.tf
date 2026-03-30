##############################################
# Locals & Data
##############################################

locals {
  common_tags = merge(
    {
      ManagedBy   = "Terraform"
      Environment = var.environment
    },
    var.tags
  )

  azs              = sort(keys(var.subnet_config))
  database_subnets = var.database_subnet_config

  nat_gateway_azs = (
    var.features.nat_gateway
    ? (
        var.features.single_nat_gateway
        ? slice(local.azs, 0, 1)
        : local.azs
      )
    : []
  )
}

##############################################
# VPC Foundation
##############################################

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = var.vpc_name })
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${var.vpc_name}-default-sg-locked" })
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${var.vpc_name}-igw" })
}

##############################################
# Subnets
##############################################

resource "aws_subnet" "public" {
  for_each                = var.subnet_config
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.public_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-public-${each.key}" })
}

resource "aws_subnet" "private" {
  for_each                = var.subnet_config
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.private_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-private-${each.key}" })
}

resource "aws_subnet" "database" {
  for_each                = local.database_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.database_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-database-${each.key}" })
}

##############################################
# Routing (Public & Private)
##############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = merge(local.common_tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_gateway_azs)
  domain   = "vpc"
  tags     = merge(local.common_tags, { Name = "${var.vpc_name}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "nat" {
  for_each      = toset(local.nat_gateway_azs)
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags       = merge(local.common_tags, { Name = "${var.vpc_name}-nat-gw-${each.key}" })
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "private" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.vpc.id
  tags     = merge(local.common_tags, { Name = "${var.vpc_name}-private-rt-${each.key}" })
}

resource "aws_route" "private_nat_route" {
  for_each               = toset(local.nat_gateway_azs)
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = var.features.single_nat_gateway ? aws_route_table.private[local.azs[0]].id : aws_route_table.private[each.key].id
}

##############################################
# Routing (Database)
##############################################

resource "aws_route_table" "database" {
  count  = length(local.database_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.common_tags, { Name = "${var.vpc_name}-database-rt" })
}

resource "aws_route_table_association" "database" {
  for_each       = aws_subnet.database
  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[0].id
}

##############################################
# Security & Auditing (Flow Logs & NACLs)
##############################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.features.flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.vpc_name}-flow-logs"
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_iam_role" "flow_logs_role" {
  count = var.features.flow_logs ? 1 : 0
  name  = "${var.vpc_name}-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  count = var.features.flow_logs ? 1 : 0
  name  = "${var.vpc_name}-flow-logs-policy"
  role  = aws_iam_role.flow_logs_role[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"],
      Effect = "Allow",
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "vpc_flow_log" {
  count           = var.features.flow_logs ? 1 : 0
  iam_role_arn    = aws_iam_role.flow_logs_role[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.vpc.id
  tags            = merge(local.common_tags, { Name = "${var.vpc_name}-flow-logs" })
}

resource "aws_network_acl" "public" {
  count      = var.features.nacl ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [for s in aws_subnet.public : s.id]
  ingress { protocol = "-1", rule_no = 100, action = "allow", cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0 }
  egress  { protocol = "-1", rule_no = 100, action = "allow", cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0 }
  tags       = merge(local.common_tags, { Name = "${var.vpc_name}-public-nacl" })
}

resource "aws_network_acl" "private" {
  count      = var.features.nacl ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [for s in aws_subnet.private : s.id]
  ingress { protocol = "-1", rule_no = 100, action = "allow", cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0 }
  egress  { protocol = "-1", rule_no = 100, action = "allow", cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0 }
  tags       = merge(local.common_tags, { Name = "${var.vpc_name}-private-nacl" })
}

resource "aws_network_acl" "database" {
  count      = (var.features.nacl && length(local.database_subnets) > 0) ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [for s in aws_subnet.database : s.id]
  ingress { protocol = "-1", rule_no = 100, action = "allow", cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0 }
  egress  { protocol = "-1", rule_no = 100, action = "allow", cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0 }
  tags       = merge(local.common_tags, { Name = "${var.vpc_name}-database-nacl" })
}

##############################################
# VPC Endpoints
##############################################

resource "aws_vpc_endpoint" "s3" {
  count             = var.features.vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = compact(concat(
    [for rt in aws_route_table.private : rt.id],
    length(aws_route_table.database) > 0 ? [aws_route_table.database[0].id] : []
  ))
  tags = merge(local.common_tags, { Name = "${var.vpc_name}-s3-endpoint" })
}

resource "aws_security_group" "vpc_endpoints_sg" {
  count       = var.features.vpc_endpoints ? 1 : 0
  name        = "${var.vpc_name}-vpce-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
  tags = merge(local.common_tags, { Name = "${var.vpc_name}-vpce-sg" })
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.features.vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints_sg[0].id]
  tags                = merge(local.common_tags, { Name = "${var.vpc_name}-ecr-api-endpoint" })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.features.vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints_sg[0].id]
  tags                = merge(local.common_tags, { Name = "${var.vpc_name}-ecr-dkr-endpoint" })
}