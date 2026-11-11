# Terraform State Recovery Runbook

## Purpose

This runbook describes the safeguards and recovery workflow for Terraform state stored in Amazon S3.

The development environment uses an S3 backend with bucket versioning and native S3 lockfile-based locking.

State recovery is a sensitive operation. Restoring an incorrect state version can cause Terraform to misidentify infrastructure and propose unintended resource changes.

**Do not restore, overwrite, or push Terraform state without explicit approval.**

## Scope

This procedure applies to:

- Terraform root: `environments/development/`
- Backend type: Amazon S3
- State key: `environments/development/terraform.tfstate`
- Locking: Native S3 lockfile using `use_lockfile = true`
- State bucket: The bucket managed by `bootstrap/terraform-state/`

The bootstrap root uses local state and is not covered by the S3 state-version recovery procedure. Its local state must be protected and backed up separately.

## Recovery principles

- Stop concurrent Terraform operations before investigating a state problem.
- Preserve the current remote state before attempting recovery.
- Preserve available S3 object versions.
- Identify the correct recovery point before changing state.
- Prefer a reviewed, documented recovery procedure over manual state editing.
- Do not disable state locking to bypass an operational problem.
- Do not use `terraform state push -force` as a routine recovery technique.
- Do not run `terraform apply` as part of state recovery.

## 1. Stop and assess

If Terraform reports a state, backend, or locking error:

1. Stop the current operation if it is safe to do so.
2. Do not start another Terraform operation against the same state.
3. Notify the project owner or responsible administrator.
4. Record the command, error message, time, AWS account, region, and intended state key.
5. Determine whether the issue is caused by backend access, permissions, locking, state corruption, or an unintended state change.

Do not delete an S3 lockfile manually to resolve a lock error. Investigate the lock owner and confirm that no active Terraform operation is using the state.

## 2. Verify the AWS identity and backend target

Verify the active AWS identity:

```bash
aws sts get-caller-identity
```

Confirm the configured bucket, region, and state key against the approved backend configuration.

The expected development state key is:

```text
environments/development/terraform.tfstate
```

Do not continue if the account, bucket, region, or key does not match the intended environment.

## 3. Preserve the current state

Before any recovery action, preserve the current state if it is accessible.

From the development root, an approved operator can export the current state to a protected backup location:

```bash
terraform state pull > /secure/path/development-terraform-state-before-recovery.tfstate
```

The destination is an example. Use an approved secure location.

Protect the backup because Terraform state can contain sensitive information.

If the current state cannot be pulled, do not assume that the remote object is empty or unusable. Preserve the S3 object and its versions using approved AWS access procedures.

## 4. Inspect S3 object versions

S3 bucket versioning allows previous versions of the state object to be retained.

An authorized operator can inspect the available versions:

```bash
aws s3api list-object-versions \
  --bucket YOUR_STATE_BUCKET_NAME \
  --prefix environments/development/terraform.tfstate
```

Replace the placeholder with the verified bucket name.

Review the output to identify:

- The current object version.
- Previous object versions.
- Version timestamps.
- Delete markers, if present.

Do not select a recovery version based only on its timestamp. Correlate the version with the last known successful Terraform operation and the expected infrastructure state.

Do not delete any object versions during investigation.

## 5. Select and validate a recovery point

Before restoring a previous state version:

1. Identify the last known good state version.
2. Confirm that the version belongs to the development environment.
3. Confirm that it corresponds to the intended AWS account and infrastructure.
4. Preserve the current state and the candidate recovery version.
5. Review the proposed recovery method with the responsible administrator.
6. Obtain explicit approval to change the active state.

Where appropriate, retrieve a candidate S3 object version to a secure local location for inspection. Do not overwrite the current state object merely to inspect a previous version.

Do not edit Terraform state JSON manually unless an approved, documented recovery procedure specifically requires it.

## 6. Restore only after explicit approval

Restoring a previous state version changes the state Terraform uses to manage infrastructure.

Before restoration, confirm:

- The candidate version has been reviewed.
- The current state has been backed up.
- No concurrent Terraform operations are running.
- The exact bucket and state key have been verified.
- The recovery method has been approved.

A recovery may involve restoring an S3 object version or using Terraform state-management commands. Choose the method based on the failure scenario and the reviewed recovery plan.

Do not blindly copy an older state file over the current state object.

Do not use `terraform state push -force` to bypass lineage or serial checks. If Terraform rejects a state operation, stop and investigate rather than overriding the safeguards.

## 7. Validate after recovery

After an approved recovery:

1. Confirm that the active state is accessible.
2. Inspect the state and verify the expected resources.
3. Confirm that the state belongs to the intended environment.
4. Preserve the pre-recovery backup and recovery evidence.
5. Generate and review a Terraform plan when authorized.

Investigate every unexpected proposed addition, modification, or deletion.

A successful state restore does not prove that the real AWS infrastructure matches the recovered state.

Do not run `terraform apply` without separate explicit deployment approval.

## 8. Document the recovery

Record:

- Incident date and time.
- AWS account and region.
- Terraform root and backend state key.
- Cause of the state issue.
- S3 object version selected.
- Backup locations.
- Recovery procedure performed.
- Validation results.
- Approver and operator.
- Outstanding risks or follow-up actions.

Keep recovery records in the approved project documentation or incident-management system. Do not include raw state contents or credentials in the record.

## Completion criteria

Recovery is complete only when:

- The active state is accessible.
- The selected state version has been reviewed.
- The expected resources are represented in state.
- The current and pre-recovery state backups are preserved.
- Terraform validation and any approved plan review are complete.
- The recovery activity is documented.

## Related documentation

- [ADR-0005: S3 Remote State Architecture](../adr/0005-s3-remote-state-architecture.md)
- [Terraform State Bootstrap Runbook](terraform-state-bootstrap.md)
- [Terraform State Migration Runbook](terraform-state-migration.md)
- [Terraform Deployment Runbook](terraform-deployment.md)