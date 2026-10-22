provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project     = "aws-bastion-private-ec2"
      Environment = "development"
      ManagedBy   = "Terraform"
    }
  }
}