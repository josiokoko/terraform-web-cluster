locals {
  az_names            = data.aws_availability_zones.azs.names
  public_subnets_ids  = aws_subnet.publicsubnet.*.id
  private_subnets_ids = aws_subnet.privatesubnet.*.id

  env_tags = {
    Environment = "${terraform.workspace}"
  }

  web_tags = merge(var.web_tags, local.env_tags)
}


resource "aws_vpc" "main_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}



#########################################################
############## Public Subnets
#########################################################

resource "aws_subnet" "publicsubnet" {
  count                   = length(local.az_names)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + 1)
  availability_zone       = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Project = ""
    Name    = "PublicSubnet-${count.index + 1}"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "igw"
  }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public subnet route table"
  }
}



resource "aws_route_table_association" "public" {
  count          = length(local.az_names)
  subnet_id      = local.public_subnets_ids[count.index]
  route_table_id = aws_route_table.public_route_table.id
}


########
######## Create NAT Gateway
########

# Create EIP for NAT GW1  
resource "aws_eip" "eip_natgw" {
  vpc = true
}



resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip_natgw.id
  subnet_id     = local.public_subnets_ids[0]
  tags = {
    Name = "gw NAT"
  }
}





#########################################################
############## Private Subnets
#########################################################

resource "aws_subnet" "privatesubnet" {
  count             = length(slice(local.az_names, 0, 2))
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + length(local.az_names) + 1)
  availability_zone = local.az_names[count.index]

  map_public_ip_on_launch = false

  tags = {
    Project = ""
    Name    = "PrivateSubnet-${count.index + 1}"
  }
}



resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private subnet route table"
  }
}



resource "aws_route_table_association" "b" {
  count          = length(slice(local.az_names, 0, 2))
  subnet_id      = local.private_subnets_ids[count.index]
  route_table_id = aws_route_table.private_route_table.id
}