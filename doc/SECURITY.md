# Security Design

## 1. Purpose

This document describes the security controls, network access boundaries, and known limitations of the AWS Bastion and Private EC2 Terraform project.

The design prioritizes least-privilege access and isolation of the private EC2 instance.

## 2. Network Access Controls

### Bastion host

- Deployed in the public subnet with a public IP address.
- Inbound SSH on TCP port 22 is restricted to the administrator CIDR configured through `admin_cidr`.
- The CIDR validation requires a valid IPv4 CIDR with a prefix between `/1` and `/32`; `/0` is rejected.
- The example CIDR is documentation-only and must be replaced with an approved administrator CIDR before deployment.

### Private EC2 instance

- Deployed in the private subnet without a public IP address.
- Inbound SSH on TCP port 22 is permitted only from the bastion security group.
- The private subnet has no configured internet default route.
- The private security group has no explicitly configured egress rules.

### Security group egress

- Bastion egress permits SSH to the private EC2 security group on TCP port 22.
- No other outbound traffic is explicitly permitted by the configured security group rules. Actual connectivity also depends on routing, network ACLs, and other applicable controls.
- Security groups are stateful, so response traffic for permitted connections is allowed automatically.

## 3. Instance Hardening

Both EC2 instances are configured with:

- IMDSv2 required for instance metadata access.
- Encrypted `gp3` root EBS volumes.
- Root volumes configured for deletion when the associated instances are terminated.
- EC2 API termination protection enabled.

Termination protection helps prevent accidental termination through supported EC2 API and console operations. It does not replace appropriate IAM permissions, backups, or reviewed infrastructure changes.

## 4. Management Access and Connectivity

The intended management path is SSH through the bastion host.

AWS Systems Manager (SSM) access is not currently configured. No SSM management path has been implemented or tested.

The private instance has no configured internet default route and no security-group egress rules. Outbound connectivity requirements must therefore be assessed before introducing workloads that need package downloads or AWS service access.

NAT Gateway and VPC endpoints are deferred until a concrete requirement justifies their implementation and associated costs.

## 5. Deployment Preconditions

Before deploying:

1. Replace the example administrator CIDR with an approved public IPv4 CIDR.
2. Confirm that the EC2 key pair exists in the selected AWS region and that the authorized administrator has access to its private key.
3. Confirm the intended AWS account and region.
4. Run formatting and validation checks.
5. Generate and review the Terraform plan for unexpected changes.
6. Obtain the required approval before applying changes in a shared AWS account.

## 6. Known Limitations

- SSH is the only management path currently designed for this project.
- Outbound connectivity for the private instance is intentionally restricted.
- Termination protection may need to be disabled before intentional instance destruction.
- The configuration has not been deployed as part of this project workflow.
- Documented controls have not necessarily been verified against deployed AWS resources.

## 7. Deferred Decisions

The following items require further evaluation before implementation:

- SSM management access and its IAM and network requirements.
- EC2 monitoring and alerting requirements.
- Additional Terraform safeguards and input validation.
- Whether future workloads require controlled outbound connectivity.

