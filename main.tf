#VPC

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }

}

# VPC default security group.
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  # Remove all default inbound and outbound rules.
  ingress = []
  egress  = []

  tags = {
    Name = "${var.project_name}-default-sg"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {

  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = false # Disabled to prevent automatic public IP assignment; reduces unintended internet exposure and does not incur a direct cost.

  tags = {
    "Name" = "${var.project_name}-public-subnet"
    "Tier" = "public"
  }
}

#Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr

  tags = {
    "Name" = "${var.project_name}-private-subnet"
    "Tier" = "private"
  }
}

#Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "${var.project_name}-public-rt"
  }
}

#Public Route
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Subnet and Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "${var.project_name}-route-table"
  }
}

# Private Route
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Bastion Security Group
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Controls access to the bastion host."
  vpc_id      = aws_vpc.main.id

  # Manage outbound access through explicit rules below.
  egress = []

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# Allow SSH to the bastion only from the configured admin CIDR.
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id

  cidr_ipv4   = var.admin_cidr
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22

  description = "SSH from approved administrator CIDR"
}

# Private EC2 Security Group
resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-ec2-sg"
  description = "Controls access to the private EC2 instnace"
  vpc_id      = aws_vpc.main.id

  # No outbound traffic is permitted unless explicitly Added.
  egress = []

  tags = {
    Name = "${var.project_name}-private-ec2-sg"
  }

}

# Allow SSH to private EC2 only from the bastion security group.
resource "aws_vpc_security_group_ingress_rule" "private_ssh" {
  security_group_id = aws_security_group.private.id

  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22

  description = "SSH from the bastion security group"
}

# Allow the bastion to initiate SSH connections to private EC2.
resource "aws_vpc_security_group_egress_rule" "bastion_to_private_ssh" {
  security_group_id = aws_security_group.bastion.id

  referenced_security_group_id = aws_security_group.private.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22

  description = "SSH to the private EC2 security group"
}