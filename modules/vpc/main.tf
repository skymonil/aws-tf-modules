# --- LOCALS (✅ FIX 5 & 10) ---
locals {
  # Standardize tags across the entire module
  common_tags = merge(
    {
      ManagedBy   = "Terraform"
      Environment = var.environment
    },
    var.tags
  )

  # 🚨 THE FIX: Extract AZs dynamically from the map keys, and SORT them 
  # so Terraform doesn't randomly shift the NAT gateway around!
  azs = sort(keys(var.subnet_config))

  # Logic: If single_nat_gateway is true, grab the FIRST sorted AZ. Otherwise, use all.
  nat_gateway_azs = var.enable_nat_gateway ? (var.single_nat_gateway ? [local.azs[0]] : local.azs) : []
}

resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = var.vpc_name })
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-igw" })
}

# ✅ FIX 4: Replaced 'count' with 'for_each' for Public Subnets
resource "aws_subnet" "public_subnet" {
  for_each = var.subnet_config

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.public_cidr # Grabs it directly from the object!
  availability_zone       = each.key               # The AZ is the map key!
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-public-${each.key}" })
}

# ✅ FIX 3: Added Private Subnets
resource "aws_subnet" "private_subnet" {
  for_each = var.subnet_config

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.private_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = false

 tags = merge(local.common_tags, { Name = "${var.vpc_name}-private-${each.key}"})
}

# --- PUBLIC ROUTING ---
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route_table_association" "public_route_table_associations" {
  # Loop over the generated public subnets dynamically
  for_each = aws_subnet.public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}


# --- HA NAT GATEWAY & PRIVATE ROUTING (✅ FIX 9, 10 & 11) ---

resource "aws_eip" "nat" {
  # We convert the local list of AZs into a set so we can use for_each!
  for_each = toset(local.nat_gateway_azs)
  domain   = "vpc"
  tags     = merge(local.common_tags, { Name = "${var.vpc_name}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "nat" {
  for_each      = toset(local.nat_gateway_azs)
  allocation_id = aws_eip.nat[each.key].id
  
  # Deploy the NAT into the matching public subnet for that AZ
  subnet_id     = aws_subnet.public_subnet[each.key].id

  tags       = merge(local.common_tags, { Name = "${var.vpc_name}-nat-gw-${each.key}" })
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "private_route_table" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.vpc.id

  

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-private-rt-${each.key}" })
}

# 2. ONLY create the route to the Internet if NAT is enabled
resource "aws_route" "private_nat_route" {
  for_each               = toset(local.nat_gateway_azs)
  route_table_id         = aws_route_table.private_route_table[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

# 3. ALWAYS associate the private subnets with their corresponding private route table
resource "aws_route_table_association" "private_route_table_associations" {
  for_each = aws_subnet.private_subnet

  subnet_id = each.value.id
  
  # Logic: If single NAT, point to the 1st AZ's route table. If HA NAT (or no NAT), point to its exact AZ.
  route_table_id = var.single_nat_gateway ? aws_route_table.private_route_table[local.azs[0]].id : aws_route_table.private_route_table[each.key].id
}