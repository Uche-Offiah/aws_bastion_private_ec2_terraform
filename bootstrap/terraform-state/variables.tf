variable "aws_region" {
  description = "AWS region where the Terraform state bucket will be created."
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform remote state S3 bucket."
  type        = string

  validation {
    condition = (
      length(var.state_bucket_name) >= 3 &&
      length(var.state_bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_name)) &&
      !startswith(var.state_bucket_name, "xn--") &&
      !startswith(var.state_bucket_name, "sthree-") &&
      !startswith(var.state_bucket_name, "amzn-s3-demo-") &&
      !endswith(var.state_bucket_name, "-s3alias") &&
      !endswith(var.state_bucket_name, "--ol-s3") &&
      !endswith(var.state_bucket_name, "--x-s3") &&
      !endswith(var.state_bucket_name, "--table-s3") &&
      !endswith(var.state_bucket_name, "-an")
    )

    error_message = "The bucket name must be 3–63 characters, contain only lowercase letters, numbers, and hyphens, start and end with a letter or number, avoid AWS-reserved prefixes and suffixes, and not use the account-regional namespace suffix."
  }
}

variable "common_tags" {
  description = "Additional tags applied to Terraform state bucket resources."
  type        = map(string)
  default     = {}
}
