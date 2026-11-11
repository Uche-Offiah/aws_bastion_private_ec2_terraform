output "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.state.arn
}

output "state_bucket_region" {
  description = "AWS region containing the Terraform state bucket."
  value       = var.aws_region
}
