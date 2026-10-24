output "vpc_id" {

  description = "ID of the project VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {

  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "private_subnet_id" {

  description = "ID of the private subnet."
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "ID of the project's Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host."
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IPv4 address of the bastion host."
  value       = aws_instance.bastion.public_ip
}

output "private_instance_id" {
  description = "Instance ID of the private EC2 instance."
  value       = aws_instance.private.id
}

output "private_instance_private_ip" {
  description = "Private IPv4 address of the private EC2 instance."
  value       = aws_instance.private.private_ip
}