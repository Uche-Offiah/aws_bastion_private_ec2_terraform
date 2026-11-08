# Terraform State Migration Runbook

## Purpose

This runbook describes the controlled migration of the development Terraform state from local storage to the Amazon S3 backend.

The migration is a state-management operation. It is separate from Terraform configuration validation and infrastructure deployment.

**The migration must not be performed without explicit approval.**

## Scope

This procedure applies to:

- Terraform root: `environments/development/`
- Backend type: Amazon S3
- State key: `environments/development/terraform.tfstate`
- Locking: Native S3 lockfile using `use_lockfile = true`
- Backend configuration: Local `backend.hcl`

The bootstrap root at `bootstrap/terraform-state/` remains on local state. It must not be migrated into the bucket it manages.

## Prerequisites

Before migration:

1. Obtain explicit approval for the state migration.
2. Confirm that the S3 bucket has been provisioned by the separate bootstrap root.
3. Verify that bucket versioning is enabled.
4. Verify that SSE-S3 encryption and S3 Block Public Access are configured.
5. Verify that the bucket policy enforces HTTPS-only access.
6. Confirm that the AWS identity has the required S3 permissions for state objects and lockfiles.
7. Confirm that no other Terraform process is operating on the development state.
8. Confirm that the development configuration and provider lockfile are committed and consistent.
9. Confirm that the current local state belongs to the intended AWS account and environment.

Do not proceed if the state bucket, account, region, state key, or local state ownership is uncertain.

## 1. Confirm the working directory

From the repository root:

```bash
cd environments/development
```

Confirm the current directory and Git status:

```bash
pwd
git status --short
```

Do not include local state files, backend configuration, or saved plans in a Git commit.

## 2. Back up the local state

Before migration, create a protected backup of the existing local state file.

If `terraform.tfstate` exists, copy it to a secure location outside the repository:

```bash
cp terraform.tfstate /secure/path/development-terraform.tfstate.pre-migration
```

The destination is an example. Replace it with an approved secure backup location.

If a local state backup already exists, preserve it rather than overwriting it.

Terraform state may contain sensitive infrastructure information. Restrict access to the backup and do not commit or transmit it through unapproved channels.

If the expected local state file does not exist, stop and establish which state currently manages the development environment before continuing.

## 3. Prepare the backend configuration

From the repository root, create the local backend configuration file from the tracked example:

```bash
cp environments/development/backend.hcl.example environments/development/backend.hcl
```

Edit `environments/development/backend.hcl` and replace the placeholder bucket name with the verified state bucket name.

Confirm the following values:

- Correct S3 bucket.
- State key: `environments/development/terraform.tfstate`.
- Correct AWS region.
- Encryption enabled.
- Native S3 lockfile enabled.

Confirm that the actual backend configuration is ignored by Git:

```bash
git check-ignore -v environments/development/backend.hcl
```

Do not commit `backend.hcl`.

## 4. Verify the AWS identity and target bucket

Verify the AWS identity:

```bash
aws sts get-caller-identity
```

Verify the bucket exists:

```bash
aws s3api head-bucket --bucket YOUR_STATE_BUCKET_NAME
```

Replace the placeholder with the approved bucket name.

Verify the bucket region and versioning configuration before migration. Do not rely solely on the Terraform configuration as proof that the bucket was provisioned correctly.

## 5. Perform the migration only after approval

**This is the state-changing step. Do not execute it without explicit migration approval.**

From the development root:

```bash
terraform init -migrate-state -backend-config=backend.hcl
```

Review Terraform's migration prompts and output carefully.

Do not use `-force-copy` to bypass migration safeguards. If Terraform reports unexpected state, backend, or lineage conditions, stop and investigate.

Do not run `terraform apply` as part of this migration procedure.

## 6. Verify the migrated state

After an approved migration, verify that Terraform can access the remote state:

```bash
terraform state list
```

Confirm that the expected managed resources are present.

Verify the remote state object exists:

```bash
aws s3api head-object \
  --bucket YOUR_STATE_BUCKET_NAME \
  --key environments/development/terraform.tfstate
```

Confirm that the local state backup remains available and protected.

Do not delete the local backup as part of migration verification.

## 7. Post-migration validation

After migration, perform configuration validation and generate a plan only when the operational approval and environment requirements permit it.

Review the plan carefully. Unexpected resource creation, modification, or destruction must be investigated.

Do not run `terraform apply` without separate explicit deployment approval.

## Rollback considerations

If migration fails or the resulting remote state is uncertain:

1. Stop further Terraform operations.
2. Preserve the local state backup.
3. Preserve any remote state object and its versions.
4. Record the error output and the last confirmed state location.
5. Do not manually overwrite the S3 object or push state.
6. Obtain approval for a recovery or rollback procedure before changing either state location.

Do not assume that rerunning `terraform init` will safely reverse a partially completed migration.

## Completion criteria

The migration is complete only when:

- The approved S3 backend is initialized successfully.
- The development state is accessible through the intended backend.
- Expected managed resources are present in the remote state.
- The remote state object exists at the intended key.
- The local pre-migration backup is preserved securely.
- No unexpected infrastructure changes have been introduced.

## Related documentation

- [ADR-0005: S3 Remote State Architecture](../adr/0005-s3-remote-state-architecture.md)
- [Terraform State Bootstrap Runbook](terraform-state-bootstrap.md)
- [Terraform State Recovery Runbook](terraform-state-recovery.md)
- [Terraform Deployment Runbook](terraform-deployment.md)