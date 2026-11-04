# Bastion Security Group
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Controls access to the bastion host."
  vpc_id      = var.vpc_id

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
  description = "Controls access to the private EC2 instance"
  vpc_id      = var.vpc_id

  # No outbound traffic is permitted unless explicitly Added.
  egress = []

  tags = {
    Name = "${var.project_name}-private-ec2-sg"
  }
}

# Allow SSH to private EC2 only from the bastion security group.
#checkov:skip=CKV_AWS_24:SSH ingress is restricted to the bastion security group, not an unrestricted CIDR; this is required for private-instance administration.
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
