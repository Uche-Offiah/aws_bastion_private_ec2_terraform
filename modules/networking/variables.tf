variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the project VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public bastion subnet."
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private EC2 subnet."
  type        = string
}
