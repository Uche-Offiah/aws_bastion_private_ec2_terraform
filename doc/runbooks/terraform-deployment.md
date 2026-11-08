# Runbook: Terraform Deployment

## 1. Purpose

This runbook describes the process for preparing, validating, and reviewing Terraform changes for the AWS Bastion and Private EC2 project.

The AWS account may contain resources managed by other projects. Every plan must therefore be reviewed before deployment.

**This runbook does not authorize deployment. Obtain explicit approval before running `terraform apply`.**

## 2. Prerequisites

Before starting, confirm that:

- Terraform and the AWS CLI are installed.
- AWS credentials are configured for the intended account.
- The selected AWS region is correct.
- The required EC2 key pair exists in that region.
- `terraform.tfvars` contains the intended values and is not committed to Git.
- The administrator CIDR has been replaced with an approved public IPv4 CIDR.
- You are working on the intended Git branch with a clean working tree, or all intended changes are clearly understood.

## 3. Confirm the AWS Identity

From the repository root, check the configured AWS identity:

```bash
aws sts get-caller-identity
```

Verify the returned account ID and identity before proceeding.

Check the selected AWS region:

```bash
aws configure get region
```

Also inspect the Terraform provider configuration and variable values. Do not assume that the AWS CLI region and Terraform provider region are necessarily identical.

## 4. Initialize Terraform

This repository has two Terraform roots with different backend responsibilities. Do not assume that both roots use the same backend.

### Bootstrap root

The bootstrap root at `bootstrap/terraform-state/` uses local state. From the repository root, local initialization and validation can be performed without provisioning AWS resources:

```bash
terraform -chdir=bootstrap/terraform-state init -backend=false -lockfile=readonly
terraform -chdir=bootstrap/terraform-state validate
```

The bootstrap state is operationally important. Keep its state file and backups secure and separate from the S3 bucket it is intended to create.

### Development root: local validation

The development root declares an S3 backend. To validate its configuration without contacting or requiring the remote bucket, use backend-disabled initialization:

```bash
terraform -chdir=environments/development init -backend=false -lockfile=readonly
terraform -chdir=environments/development validate
```

This verifies local Terraform configuration and provider initialization; it does not verify S3 access, remote state, or locking.

### Development root: remote initialization

Remote initialization is not yet an approved or completed operation. Do not run it until the S3 bucket has been provisioned and verified, the actual local `environments/development/backend.hcl` has been populated with the approved bucket details, the AWS identity and permissions have been checked, and explicit approval has been obtained.

The intended command, for a separately approved migration or initialization procedure, is:

```bash
terraform -chdir=environments/development init -backend-config=backend.hcl
```

If an existing local state must be migrated, the operator must follow [the Terraform State Migration Runbook](terraform-state-migration.md). Do not add `-migrate-state` or `-reconfigure` as an exploratory step.

## 5. Terraform State Safety

Terraform state can contain sensitive infrastructure details and must be protected. This project has separate state responsibilities:

- The bootstrap root uses local state. Keep its state and verified backups in a secure, access-controlled location. It must not depend on the S3 bucket that it provisions.
- The development root declares an S3 backend with the state key `environments/development/terraform.tfstate` and native S3 lockfile-based locking. The bucket has not yet been provisioned, and development state migration has not been performed.
- The actual `backend.hcl` file is local configuration and must not be committed. The tracked `.example` file is a template, not a working account-specific configuration.
- Never commit Terraform state, state backups, saved plan files, credentials, or sensitive variable files.
- Do not delete, manually edit, or replace state files as a troubleshooting shortcut.
- Do not run concurrent operations against the same state outside Terraform's locking controls.
- Before any migration or recovery, confirm the authoritative state, AWS account, bucket, region, and key; create and verify a secure backup; and obtain explicit approval.
- If state is lost, corrupted, or appears inconsistent with AWS, stop and follow [the Terraform State Recovery Runbook](terraform-state-recovery.md).

Backend-disabled initialization is for local validation only. It does not prove that the remote backend is available or correctly configured.

## 6. Format and Validate

Run:

```bash
terraform fmt -check -recursive
terraform validate
```

Resolve formatting or validation failures before continuing.

## 7. Review the Proposed Changes

Generate a plan only after initializing the intended backend and confirming that the correct state is loaded. For the development root, remote planning requires the separately approved S3 backend initialization described in Section 4. Backend-disabled validation alone is not sufficient.

From the relevant root directory, generate a plan:

```bash
terraform plan -out=tfplan
```

Inspect the plan in readable form:

```bash
terraform show -no-color tfplan
```

Review all proposed resource additions, modifications, and deletions. Pay particular attention to:

- Resources belonging to other projects.
- VPCs, subnets, route tables, and security groups.
- Public IP assignments and ingress/egress rules.
- EC2 instance replacement or termination.
- EBS volumes, snapshots, and data retention.
- Changes to IAM permissions or network connectivity.

If the plan contains unexpected changes, stop and investigate.

The saved plan may contain sensitive information. Do not commit it, upload it to an unapproved location, or share it publicly.

## 8. Approval and Application

Do not apply the plan until the required approval has been obtained.

After approval, apply the reviewed saved plan:

```bash
terraform apply tfplan
```

Applying a saved plan uses the proposed actions in that plan rather than interactively generating a new plan. If Terraform reports that the plan is stale, generate and review a new plan and obtain approval again.

Do not use `-auto-approve` as a substitute for review or approval.

## 9. Post-Deployment Verification

If deployment is explicitly approved and completed:

```bash
terraform output
terraform state list
```

Verify the resulting resources in the AWS console or through appropriate AWS CLI commands.

Confirm that the deployed network configuration matches the reviewed plan. Record any discrepancies and investigate them before declaring the deployment successful.

## 10. Cleanup

When deployment testing is complete, follow [the Terraform Destruction Runbook](terraform-destruction.md). Do not assume that all resources can be safely removed without reviewing their dependencies and data-retention requirements.