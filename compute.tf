resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true # Required for the current direct-SSH access model; public IPv4 addresses incur a charge, so consider SSM access in a future iteration.

  monitoring    = true # Enables detailed CloudWatch monitoring for faster operational visibility; incurs additional monitoring charges.
  ebs_optimized = true # Enables optimized EBS I/O; generally beneficial for performance, with no separate charge for supported instance types.

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Enforces IMDSv2 to reduce the risk of SSRF-based metadata credential theft; no additional charge.
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true # Encrypts data at rest; standard EBS encryption has no additional charge when using the default AWS-managed key.
    delete_on_termination = true
  }

  disable_api_termination = true # Helps prevent accidental termination through the EC2 API; no additional charge.

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

resource "aws_instance" "private" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.private_instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = false # Keeps the private instance from receiving a public IP; improves isolation and has no direct additional cost.

  monitoring    = true # Enables detailed CloudWatch monitoring for faster operational visibility; incurs additional monitoring charges.
  ebs_optimized = true # Enables optimized EBS I/O; generally beneficial for performance, with no separate charge for supported instance types.

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # Enforces IMDSv2 to reduce the risk of SSRF-based metadata credential theft; no additional charge.
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true # Encrypts data at rest; standard EBS encryption has no additional charge when using the default AWS-managed key.
    delete_on_termination = true
  }

  disable_api_termination = true # Helps prevent accidental termination through the EC2 API; no additional charge.

  tags = {
    Name = "${var.project_name}-private-ec2"
  }
}
