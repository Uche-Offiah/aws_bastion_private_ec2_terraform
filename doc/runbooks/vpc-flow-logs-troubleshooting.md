# Runbook: VPC Flow Logs Troubleshooting

## 1. Purpose

This runbook describes how to investigate VPC Flow Logs delivery and review network traffic records for the AWS Bastion and Private EC2 project.

The Terraform configuration creates a VPC Flow Log that captures all traffic and delivers records to a CloudWatch Logs log group. These resources have not necessarily been deployed or verified.

## 2. Expected Configuration

The Terraform configuration defines:

- **Traffic type:** `ALL`.
- **Destination:** CloudWatch Logs.
- **Log group:** `/aws/vpc/${var.project_name}/flow-logs`.
- **Retention:** Configurable through `flow_log_retention_days`.
- **Delivery role:** An IAM role assumed by the VPC Flow Logs service.

Flow Logs provide network-flow metadata, not packet captures. They do not independently provide application-level diagnostics or guarantee immediate visibility of every connection.

## 3. Verify the AWS Context

Before investigating, confirm the AWS account and region:

```bash
aws sts get-caller-identity
aws configure get region
```

Check the Terraform configuration for the intended `aws_region` value as well. Do not assume the CLI and Terraform use the same region.

## 4. Check the Flow Log and Log Group

Using the AWS console or read-only AWS CLI queries, verify:

- The intended VPC exists.
- A VPC Flow Log is associated with that VPC.
- Its traffic type is `ALL`.
- Its destination is CloudWatch Logs.
- Its delivery status and any reported errors are reviewed.
- The expected CloudWatch Logs log group exists in the intended region.
- Log streams are receiving records.
- The configured retention period matches the intended value.

A missing log group or missing recent records does not, by itself, identify the cause. Consider whether the configuration has been deployed, whether traffic has occurred, and whether delivery has had sufficient time.

## 5. Investigate Missing Records

If expected records are absent:

1. Confirm the AWS account and region.
2. Confirm that the VPC Flow Log exists and is associated with the correct VPC.
3. Review its delivery status and any reported errors.
4. Confirm the destination log group and available log streams.
5. Review the IAM role trust policy and permissions for CloudWatch Logs delivery.
6. Confirm that the log group and Flow Log configuration match the current Terraform configuration.
7. Check whether the traffic occurred within the period being investigated.

Do not broaden IAM permissions or replace the logging configuration without identifying the suspected cause and reviewing the proposed change.

## 6. Retention, Access, and Cost

The configured retention period controls how long CloudWatch Logs retains log events before expiry. Confirm the retention setting before changing it.

Flow Logs and CloudWatch Logs can incur charges for log ingestion, storage, and related usage. Capturing `ALL` traffic may generate substantial log volume in a busy VPC.

Before increasing retention or changing the logging scope, evaluate troubleshooting and audit requirements, expected volume, and cost.

Access to the log group should be limited to authorized operators. Do not publish logs or copy sensitive operational details into unapproved locations.

## 7. Limitations and Escalation

VPC Flow Logs do not replace CloudWatch alarms, application logs, host-level telemetry, or an incident-response process. A lack of recorded traffic does not prove that the network is secure or that no connection attempt occurred.

If the issue remains unresolved:

1. Record the VPC ID, AWS account, region, Flow Log ID, and destination log group.
2. Record the approximate time range and observed delivery status.
3. Collect relevant read-only configuration and error details.
4. Identify the likely cause before proposing changes.
5. Obtain approval and review the Terraform plan before applying any infrastructure changes.

## 8. Related Documentation

- [Architecture Overview](../ARCHITECTURE.md)
- [Security Design](../SECURITY.md)
- [Terraform Deployment Runbook](terraform-deployment.md)
- [Terraform Destruction Runbook](terraform-destruction.md)
