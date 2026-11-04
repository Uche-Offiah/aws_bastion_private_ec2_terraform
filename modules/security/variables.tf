variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups will be created."
  type        = string
}

variable "admin_cidr" {
  description = "Approved public IPv4 CIDR allowed to connect to the bastion over SSH."
  type        = string
}
