output "bastion_instance_id" {
  description = "ID of the bastion EC2 instance."
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IPv4 address of the bastion EC2 instance."
  value       = aws_instance.bastion.public_ip
}

output "private_instance_id" {
  description = "ID of the private EC2 instance."
  value       = aws_instance.private.id
}

output "private_instance_private_ip" {
  description = "Private IPv4 address of the private EC2 instance."
  value       = aws_instance.private.private_ip
}
