output "bastion_security_group_id" {
  description = "ID of the bastion security group."
  value       = aws_security_group.bastion.id
}

output "private_security_group_id" {
  description = "ID of the private EC2 security group."
  value       = aws_security_group.private.id
}
