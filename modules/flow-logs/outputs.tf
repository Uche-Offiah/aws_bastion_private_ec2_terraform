output "log_group_name" {
  description = "Name of the CloudWatch log group receiving VPC Flow Logs."
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "flow_log_id" {
  description = "ID of the VPC Flow Logs resource."
  value       = aws_flow_log.main.id
}