
data "aws_availability_zones" "available_zones" {
  state = "available"
}

resource "aws_vpc" "web_app_vpc" {
  cidr_block           = var.vpc_cidr_def
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Web App VPC"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.web_app_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.web_app_igw.id
}

resource "aws_internet_gateway" "web_app_igw" {
  vpc_id = aws_vpc.web_app_vpc.id
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.web_app_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.web_app_vpc.cidr_block, 8, 2 + count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.web_app_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.web_app_vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  tags = {
    Name = "private-subnet"
  }

}

resource "aws_eip" "EIP" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.web_app_igw]
}


resource "aws_nat_gateway" "NAT_gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.EIP.*.id, count.index)
  tags = {
    Name = "NAT Gateway"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.web_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.NAT_gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)

}

resource "aws_vpc_endpoint" "secret_endpoint" {
  service_name       = "com.amazonaws.us-west-2.secretsmanager"
  vpc_id             = aws_vpc.web_app_vpc.id
  security_group_ids = [aws_security_group.vpce_sg.id]
  vpc_endpoint_type  = "Interface"
}