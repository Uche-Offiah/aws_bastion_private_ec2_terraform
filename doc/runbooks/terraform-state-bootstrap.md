# Runbook: Terraform State Backend Bootstrap

## 1. Purpose

This runbook describes the preparation and review of the S3 backend bucket using the separate Terraform bootstrap root.

The bootstrap root is located at `bootstrap/terraform-state/`. It uses local state and provisions the S3 bucket intended for environment state.

**This runbook does not authorize AWS provisioning. Obtain separate explicit approval before running `terraform apply`.**

## 2. Bootstrap design

The bootstrap configuration defines:

- S3 bucket versioning.
- SSE-S3 server-side encryption.
- S3 Block Public Access controls.
- Bucket-owner-enforced object ownership.
- An HTTPS-only bucket policy.
- `prevent_destroy = true` and `force_destroy = false`.

The bootstrap root must retain local state. Do not configure it to store its own state in the bucket it provisions.

## 3. Prerequisites

Before provisioning:

1. Confirm the intended AWS account and region.
2. Obtain approval to create the S3 bucket in the shared AWS account.
3. Select a globally unique bucket name.
4. Confirm that the intended AWS identity has the required permissions.
5. Establish a secure backup location for the bootstrap state.
6. Review the Terraform configuration and plan.

Do not commit `terraform.tfstate`, state backups, credentials, or account-specific configuration.

## 4. Local initialization and validation

From the repository root:

```bash
terraform -chdir=bootstrap/terraform-state init -backend=false -lockfile=readonly
terraform -chdir=bootstrap/terraform-state validate
terraform fmt -check -recursive