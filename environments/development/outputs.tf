output "vpc_id" {
  description = "ID of the project VPC."
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public bastion subnet."
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private EC2 subnet."
  value       = module.networking.private_subnet_id
}

output "internet_gateway_id" {
  description = "ID of the VPC internet gateway."
  value       = module.networking.internet_gateway_id
}

output "bastion_instance_id" {
  description = "ID of the bastion EC2 instance."
  value       = module.compute.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion EC2 instance."
  value       = module.compute.bastion_public_ip
}

output "private_instance_id" {
  description = "ID of the private EC2 instance."
  value       = module.compute.private_instance_id
}

output "private_instance_private_ip" {
  description = "Private IP address of the private EC2 instance."
  value       = module.compute.private_instance_private_ip
}
