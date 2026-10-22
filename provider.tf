provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project     = var.Project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}