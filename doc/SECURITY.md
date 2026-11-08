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
- Alerting and operational response requirements for VPC Flow Logs and EC2 monitoring.
- Verification of Flow Logs delivery, log access permissions, and retention after deployment.
- Additional Terraform safeguards and input validation.
- Whether future workloads require controlled outbound connectivity.

## 8. Terraform State Security

Terraform state can contain sensitive infrastructure information and must be treated as sensitive data. The following controls and operational requirements apply to the state architecture:

- The bootstrap root uses local state and does not store its own state in the S3 bucket it provisions.
- Bootstrap state files and backups must be kept in an access-controlled, protected location and must not be committed to version control.
- The intended S3 bucket configuration enables versioning, SSE-S3 encryption, all S3 Block Public Access settings, `BucketOwnerEnforced` ownership controls, and a bucket policy that denies non-TLS requests. These are configuration intentions until the bucket is provisioned and verified in AWS.
- The development backend uses a separate state key and native S3 lockfile-based locking through `use_lockfile = true`.
- The actual backend configuration file is excluded from version control. Credentials must be supplied through the approved AWS credential chain, not embedded in backend configuration.
- Access to state objects and lockfiles must follow least-privilege principles. Required IAM permissions must be reviewed for the intended operators and automation; this project has not created or modified shared-account IAM policies.
- S3 versioning supports recovery of prior object versions but does not replace secure backups, access controls, or a reviewed recovery procedure.
- State migration and restoration require a verified backup, confirmation of the intended account, bucket, region, and key, and explicit approval.

The S3 bucket has not yet been provisioned. Encryption, versioning, public-access blocking, transport enforcement, and remote locking have not been verified against live AWS resources.

## 9. Terraform Security Configuration Organization

Security-related Terraform resources are maintained in the following modules:

- `modules/security/` — Security groups and explicit ingress and egress rules.
- `modules/compute/` — EC2 instance hardening, including IMDSv2, encrypted root volumes, and termination protection.
- `modules/networking/` — VPC boundaries, subnet isolation, and route table configuration.
- `modules/flow-logs/` — VPC Flow Logs, CloudWatch logging, and the associated IAM permissions.

The development environment composes these modules through `environments/development/`.

Environment-specific configuration, including the administrator CIDR and EC2 key pair, remains separate from reusable module implementation.

Each environment maintains independent Terraform state. The bootstrap root uses local state, while the development root declares an S3 backend with its own state key. The S3 bucket has not yet been provisioned, and the development state has not been migrated. Local validation uses backend-disabled initialization so that it does not require the remote bucket.

Modularization must not introduce broader network access, unrestricted security-group rules, or changes to the security decisions documented above.