terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
  access_key = aws-access-key
  secret_key = aws-secret-key
}

resource "aws_instance" "splunk" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}

# Create a VPC
resource "aws_vpc" "vpc-splunk" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags = {
    Name = "vpc-Splunk"
  }
}

# IG for the public subnet
resource "aws_internet_gateway" "ig-splunk" {
  vpc_id = "aws_vpc.vpc-splunk.id"
  tags = {
    Name  = "ig-splunk"
  }
}

# EIP for NAT
resource "aws_eip" "eip-splunk" {
  vpc         = true
  depends_on  = [aws_internet_gateway.ig-splunk]
}

# NAT
resource "aws_nat_gateway" "nat-splunk" {
  allocation_id = "aws_eip.eip-splunk.id"
  subnet_id     = "aws_subnet.sn-public.*.id"
  depends_on    = "aws_internet_gateway.ig-splunk"
}

# Public Subnet
resource "aws_subnet" "sn_public" {
  vpc_id                  = "aws_vpc.vpc-splunk.id"
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "sn_public-zone"
  }
}

# Private Subnet
resource "aws_subnet" "sn_private" {
  vpc_id                  = "aws_vpc.vpc-splunk.id"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false
  tags = {
    Name = "sn_private-zone"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "rt-public" {
  vpc_id = "aws_vpc.vpc-splunk.id"
  tags = {
    Name = "rt-splunk"
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "rt-private" {
  vpc_id = "aws_vpc.vpc-splunk.id"
  tags = {
    Name = "rt-private"
  }
}

# Route for Public IG
resource "aws_route" "ig-public" {
  route_table_id  = "aws_route_table.rt-public.id"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "aws_internet_gateway.ig-splunk.id"
}

# Route for NAT
resource "aws_route" "ig-private" {
  route_table_id  = "aws_route_table.rt-private.id"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "aws_nat_gateway.nat-splunk.id"
}

# Route Table Association for Public
resource "aws_route_table_association" "rta-public" {
  subnet_id      = "aws_subnet.sn-public.id"
  route_table_id = "aws_route_table.rt-public.id}"
}

# Route Table Association for Private
resource "aws_route_table_association" "rta-private" {
  subnet_id      = "aws_subnet.sn-private.id"
  route_table_id = "aws_route_table.rt-private.id"
}

/*==== VPC's Default Security Group ======*/
resource "aws_security_group" "default" {
  name        = "sg-default"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "aws_vpc.vpc-splunk.id}"
  depends_on  = [aws_vpc.vpc-splunk]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags = {
    Name = "sg-default"
  }
}
