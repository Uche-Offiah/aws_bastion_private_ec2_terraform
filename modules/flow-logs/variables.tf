variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "aws_region" {
  description = "AWS region where VPC Flow Logs resources are created."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC whose traffic will be captured."
  type        = string
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch."
  type        = number
}