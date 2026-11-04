# Bastion EC2 instance.
#checkov:skip=CKV_AWS_88:Public IP is intentional for the current direct-SSH bastion architecture; SSH ingress is restricted to the configured administrator CIDR.
#checkov:skip=CKV2_AWS_41:No EC2 instance role is needed for the current workload because it does not require AWS API permissions; reassess if SSM or other AWS integrations are introduced.
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [var.bastion_security_group_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true # Required for the current direct-SSH access model.

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  disable_api_termination = true

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

# Private EC2 instance.
#checkov:skip=CKV2_AWS_41:No EC2 instance role is needed for the current workload because it does not require AWS API permissions; reassess if SSM or other AWS integrations are introduced.
resource "aws_instance" "private" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.private_instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.private_security_group_id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = false

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  disable_api_termination = true

  tags = {
    Name = "${var.project_name}-private-ec2"
  }
}
