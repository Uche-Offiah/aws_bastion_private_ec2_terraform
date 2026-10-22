variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "us-east-2"
}

variable "Project_name" {
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