data "aws_caller_identity" "current" {}


#checkov:skip=CKV_AWS_338:30-day retention is the deliberate development default to balance troubleshooting needs and log-storage costs; production audit requirements may require longer retention.
#checkov:skip=CKV_AWS_158:Customer-managed KMS encryption is deferred to avoid additional key-management complexity and potential cost; CloudWatch Logs default encryption at rest remains enabled.
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}/flow-logs"
  retention_in_days = var.flow_log_retention_days

  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-vpc-flow-logs-role"
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteFlowLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      },
      {
        Sid      = "CreateProjectLogGroup"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = aws_cloudwatch_log_group.vpc_flow_logs.arn
      },
      {
        Sid      = "DescribeLogGroups"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "main" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn

  depends_on = [aws_iam_role_policy.vpc_flow_logs]

  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}