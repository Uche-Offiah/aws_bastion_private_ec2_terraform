variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
  default     = "aws-bastion-private-ec2"
}

variable "environment" {
  description = "Environment name used for resource tagging."
  type        = string
  default     = "development"
}

variable "vpc_cidr" {
  description = "CIDR range for the aws-bastion-private-ec2 project"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public bastion subnet"
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private ec2 subnet"
  type        = string
  default     = "10.20.2.0/24"
}

variable "admin_cidr" {
  description = "Approved public IPv4 CIDR allowed to connect bastion over SSH"
  type        = string

  validation {
    condition = (
      can(cidrhost(var.admin_cidr, 0)) &&                      # parse and get the first host IP
      can(regex("/([0-9]|[12][0-9]|3[0-2])$", var.admin_cidr)) # check to ensure a valid CIDR /0-32. [12][0-9] matches /10 to /29. $ ensure pattern occur at the end of the string
    )
    error_message = "admin_cidr must be valid IPv4 CIDR, such as 198.51.100.25/32."
  }
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "private_instance_type" {
  description = "EC2 instance type for the private EC2 instance."
  type        = string
  default     = "t3.micro"
}