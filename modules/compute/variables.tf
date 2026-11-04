variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "bastion_subnet_id" {
  description = "ID of the public subnet hosting the bastion."
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet hosting the private EC2 instance."
  type        = string
}

variable "bastion_security_group_id" {
  description = "ID of the bastion security group."
  type        = string
}

variable "private_security_group_id" {
  description = "ID of the private EC2 security group."
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host."
  type        = string
}

variable "private_instance_type" {
  description = "EC2 instance type for the private EC2 instance."
  type        = string
}

variable "key_pair_name" {
  description = "Name of the existing EC2 key pair used for SSH authentication."
  type        = string
}
