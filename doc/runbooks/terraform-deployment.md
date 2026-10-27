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

```bash
terraform init
```

Initialization downloads the required provider plugins and prepares the working directory.

If provider dependencies change, review the changes to `.terraform.lock.hcl` before committing.

## 5. Format and Validate

Run:

```bash
terraform fmt -check -recursive
terraform validate
```

Resolve formatting or validation failures before continuing.

## 6. Review the Proposed Changes

Generate a plan:

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

## 7. Approval and Application

Do not apply the plan until the required approval has been obtained.

After approval, apply the reviewed saved plan:

```bash
terraform apply tfplan
```

Applying a saved plan uses the proposed actions in that plan rather than interactively generating a new plan. If Terraform reports that the plan is stale, generate and review a new plan and obtain approval again.

Do not use `-auto-approve` as a substitute for review or approval.

## 8. Post-Deployment Verification

If deployment is explicitly approved and completed:

```bash
terraform output
terraform state list
```

Verify the resulting resources in the AWS console or through appropriate AWS CLI commands.

Confirm that the deployed network configuration matches the reviewed plan. Record any discrepancies and investigate them before declaring the deployment successful.

## 9. Cleanup

When deployment testing is complete, follow [the Terraform Destruction Runbook](terraform-destruction.md). Do not assume that all resources can be safely removed without reviewing their dependencies and data-retention requirements.