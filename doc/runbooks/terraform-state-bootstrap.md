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
```

Confirm that initialization and validation complete successfully before proceeding.

The `-backend=false` option ensures that the bootstrap root initializes without attempting to use a remote backend.

## 5. Confirm the AWS identity and configuration

Before creating or changing AWS resources, verify the active AWS identity:

```bash
aws sts get-caller-identity
```

Review the local bootstrap variables:

```bash
cat bootstrap/terraform-state/terraform.tfvars
```

Confirm the intended region and globally unique bucket name.

The actual `terraform.tfvars` file is account-specific and must remain untracked by Git.

If the file does not exist, create it using the committed example as a reference:

```bash
cp bootstrap/terraform-state/terraform.tfvars.example \
  bootstrap/terraform-state/terraform.tfvars
```

## 6. Back up the bootstrap state

The bootstrap state is local and independent of the S3 bucket it creates.

Before modifying an existing bootstrap deployment, preserve a backup of the current state.

For Git Bash:

```bash
BACKUP_DIR="$HOME/terraform-state-backups/aws-bastion-private-ec2"

mkdir -p "$BACKUP_DIR"

if [ -f bootstrap/terraform-state/terraform.tfstate ]; then
  cp bootstrap/terraform-state/terraform.tfstate \
    "$BACKUP_DIR/terraform.tfstate.$(date +%Y%m%d-%H%M%S).backup"

  sha256sum bootstrap/terraform-state/terraform.tfstate
  sha256sum "$BACKUP_DIR"/terraform.tfstate.*.backup
else
  echo "No existing bootstrap state file found. This may be the initial bootstrap."
fi
```

Store backups in a secure location outside the repository.

For an existing state file, verify that the backup was created successfully and that its checksum matches the source file.

Do not overwrite or delete existing backups as part of this procedure.

## 7. Generate and review the bootstrap plan

Generate a saved plan:

```bash
terraform -chdir=bootstrap/terraform-state plan \
  -out="$HOME/terraform-state-backups/aws-bastion-private-ec2/bootstrap.tfplan"
```

Review the plan:

```bash
terraform -chdir=bootstrap/terraform-state show \
  "$HOME/terraform-state-backups/aws-bastion-private-ec2/bootstrap.tfplan"
```

Confirm that:

- The intended bucket name is correct.
- The intended AWS region is correct.
- The proposed resources match the reviewed bootstrap configuration.
- Versioning is enabled.
- SSE-S3 encryption is configured.
- Public access is blocked.
- Object ownership is bucket-owner-enforced.
- The HTTPS-only bucket policy is configured.
- `prevent_destroy` and `force_destroy = false` are retained.
- No unrelated AWS resources or unexpected changes are proposed.

Stop if the plan contains unexpected changes.

A saved plan may contain sensitive information. Keep it outside the repository and protect it accordingly.

## 8. Provisioning approval gate

After approval, apply the exact saved plan that was reviewed:

```bash
terraform -chdir=bootstrap/terraform-state apply \
  "$HOME/terraform-state-backups/aws-bastion-private-ec2/bootstrap.tfplan"
```

Do not generate a different plan and apply it without reviewing the new proposal and obtaining any required approval.

If the apply fails or produces unexpected results, stop and investigate. Do not attempt to resolve unexpected state or infrastructure changes by deleting the bucket or forcing a state operation.

## 9. Verify the provisioned S3 bucket

Set the bucket name and region to the approved values:

```bash
BUCKET="replace-with-actual-bucket-name"
REGION="us-east-2"
```

Verify that the bucket exists and is accessible:

```bash
aws s3api head-bucket \
  --bucket "$BUCKET"
```

Verify the bucket region:

```bash
aws s3api get-bucket-location \
  --bucket "$BUCKET"
```

Verify versioning:

```bash
aws s3api get-bucket-versioning \
  --bucket "$BUCKET"
```

Expected result:

```json
{
  "Status": "Enabled"
}
```

Verify default encryption:

```bash
aws s3api get-bucket-encryption \
  --bucket "$BUCKET"
```

Confirm that the default encryption algorithm is `AES256`.

Verify all public-access block settings:

```bash
aws s3api get-public-access-block \
  --bucket "$BUCKET"
```

Confirm that all four settings are `true`:

- `BlockPublicAcls`
- `IgnorePublicAcls`
- `BlockPublicPolicy`
- `RestrictPublicBuckets`

Verify object ownership:

```bash
aws s3api get-bucket-ownership-controls \
  --bucket "$BUCKET"
```

Confirm that the ownership mode is `BucketOwnerEnforced`.

Verify the bucket policy:

```bash
aws s3api get-bucket-policy \
  --bucket "$BUCKET" \
  --query Policy \
  --output text
```

Review the policy and confirm that it denies requests where `aws:SecureTransport` is `false`.

If a verification command fails or the returned configuration differs from the intended design, stop and investigate before using the bucket for environment state.

## 10. Verify Terraform outputs and preserve the bootstrap state

Review the bootstrap outputs:

```bash
terraform -chdir=bootstrap/terraform-state output
```

Confirm that the bucket name, ARN, and region correspond to the intended bucket.

After successful provisioning, back up the resulting local bootstrap state:

```bash
BACKUP_DIR="$HOME/terraform-state-backups/aws-bastion-private-ec2"

mkdir -p "$BACKUP_DIR"

cp bootstrap/terraform-state/terraform.tfstate \
  "$BACKUP_DIR/terraform.tfstate.post-bootstrap"

sha256sum bootstrap/terraform-state/terraform.tfstate
sha256sum "$BACKUP_DIR/terraform.tfstate.post-bootstrap"
```

Verify the backup and retain it in the secure backup location.

The bootstrap state must remain local. Do not migrate it into the S3 bucket it manages.

## 11. Post-bootstrap safeguards

After successful verification:

1. Keep the bootstrap Terraform state local.
2. Retain secure, verified backups of the bootstrap state.
3. Keep account-specific variables and saved plans out of Git.
4. Do not disable bucket versioning, encryption, public-access blocking, or the HTTPS-only policy without an approved architectural change.
5. Do not remove `prevent_destroy` or enable `force_destroy` as a routine troubleshooting measure.
6. Do not destroy the bootstrap bucket as part of normal project operations.
7. Use the separate development backend configuration and migration runbook when configuring an environment root to use remote state.

The bootstrap bucket should be treated as a critical infrastructure dependency. Changes to it require careful review and explicit authorization.

## 12. Operational boundaries

This runbook covers the bootstrap bucket only.

It does not authorize:

- Applying the development environment Terraform configuration.
- Creating or modifying the bastion or private EC2 instances.
- Migrating bootstrap state into S3.
- Deleting the S3 bucket or its object versions.
- Disabling state protection controls.
- Performing forced state operations.

The development environment must be planned and reviewed separately. Any infrastructure deployment requires its own explicit approval.

## 13. Related documentation

- `doc/ARCHITECTURE.md`
- `doc/SECURITY.md`
- `doc/ROADMAP.md`
- `doc/adr/0005-s3-remote-state-architecture.md`
- `doc/runbooks/terraform-deployment.md`
- `doc/runbooks/terraform-state-migration.md`
- `doc/runbooks/terraform-state-recovery.md`