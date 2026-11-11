provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-bastion-private-ec2"
      Environment = "bootstrap"
      ManagedBy   = "Terraform"
    }
  }
}
