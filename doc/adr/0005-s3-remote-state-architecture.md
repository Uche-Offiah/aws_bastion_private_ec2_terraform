# ADR-0005: S3 Remote State and Separate Bootstrap Architecture

- **Status:** Proposed
- **Date:** 2026-11-04

## Context

Iteration 6 introduced independent Terraform root configurations for each environment while retaining local state. Iteration 7 introduces a secure, recoverable remote-state workflow for shared use without making remote infrastructure a prerequisite for local development.

The solution must:

- Keep backend provisioning separate from the infrastructure that consumes the backend.
- Support independent state objects for each environment.
- Provide state locking to prevent concurrent state modifications.
- Protect state through encryption, versioning, public-access blocking, and secure transport.
- Apply least-privilege access controls.
- Preserve a practical local initialization and validation workflow.
- Provide documented backup, migration, and recovery procedures.
- Avoid committing state, credentials, or account-specific backend configuration.

The AWS account is shared with other projects. Backend provisioning and any state migration therefore require separate review and explicit authorization. Implementing the configuration does not authorize provisioning AWS resources.

## Decision

Use an Amazon S3 backend for environment state, provisioned through a dedicated Terraform bootstrap configuration.

### 1. Separate bootstrap configuration

Create a standalone Terraform root at `bootstrap/terraform-state/`.

The bootstrap configuration will:

- Use Terraform's default local backend for its own state.
- Provision the S3 bucket used for environment state.
- Enable S3 bucket versioning.
- Enable server-side encryption using SSE-S3.
- Block all S3 public access.
- Enforce secure transport using a bucket policy that denies insecure HTTP requests.
- Apply appropriate bucket ownership and access controls.
- Output the bucket name, ARN, and region needed by environment backend configuration.
- Require a globally unique S3 bucket name supplied through bootstrap configuration and create the bucket as part of the bootstrap process; do not assume the backend bucket already exists.

The bootstrap state will remain local by default. It will be protected and backed up securely and excluded from version control. It will not be migrated into the same bucket it provisions, avoiding a circular dependency during backend recovery.

IAM identity permissions will be documented and scoped separately. The bootstrap configuration will not create or modify shared-account IAM users, roles, or policies without a separately reviewed requirement.

### 2. Environment remote state

Environment roots will use the S3 backend with distinct object keys.

The development state key will be:

`environments/development/terraform.tfstate`

Future environments must use their own unique keys. Staging and production roots are not introduced by this decision.

The S3 backend will use Terraform's native S3 lockfile mechanism:

`use_lockfile = true`

A DynamoDB lock table will not be introduced by default.

The backend will use the bucket region and encryption configuration established by the bootstrap process. Credentials will be obtained through the standard AWS credential chain, such as an approved AWS CLI profile or role. Credentials and secrets must not be embedded in backend configuration files.

### 3. Backend configuration and local compatibility

The development root will declare an S3 backend using partial backend configuration. Account-specific bucket details will be supplied through a local backend configuration file, with a tracked example provided for reference.

The actual backend configuration file will be excluded from version control.

Two initialization workflows will be documented:

- Local workflow: `terraform init -backend=false`
- Remote workflow: `terraform init -backend-config=backend.hcl`

The local workflow must remain independently usable without a provisioned S3 bucket or remote-backend permissions. CI validation will use backend-disabled initialization.

### 4. State migration and recovery

State migration will only be performed after:

- Confirming the intended AWS account, bucket, region, and state key.
- Confirming that the destination bucket and required permissions are available.
- Creating and verifying a secure backup of the existing state.
- Reviewing the migration procedure and obtaining explicit approval.

Terraform backend migration will use a reviewed initialization procedure. Existing state must not be deleted, overwritten, or discarded as part of routine setup.

Recovery procedures will explain how to identify and restore a prior S3 object version safely. A subsequent Terraform plan must be reviewed after migration or recovery.

No migration, state restoration, bucket provisioning, or infrastructure deployment is authorized solely by accepting this ADR.

## Alternatives considered

### 1. Continue using local state only

Advantages:
- No additional AWS resources or permissions.
- Simple initialization and operation.
- Preserves the existing individual-developer workflow.

Disadvantages:
- State is not shared automatically between operators.
- No centralized remote locking or version history.
- Collaboration and recovery require manual coordination.

This remains supported for local use but does not satisfy the shared-use objective.

### 2. Use an S3 backend with manually provisioned bucket infrastructure

Advantages:
- Minimal Terraform bootstrap code.
- The bucket can be provisioned through an existing organizational process.

Disadvantages:
- Bucket configuration and security controls may drift from the repository's documented design.
- Reproducibility depends on external procedures.
- Infrastructure ownership and maintenance are less visible in this project.

This is not selected because a dedicated, reviewable bootstrap configuration provides a reproducible implementation.

### 3. Provision the backend using the same environment configuration

Advantages:
- Fewer Terraform root configurations.
- A single configuration appears to manage all resources.

Disadvantages:
- Creates a dependency between the backend and the configuration that requires it.
- Complicates initial provisioning and backend recovery.
- Risks circular dependencies during state migration or restoration.

This is rejected in favor of a separate bootstrap root.

### 4. Use a remote backend for the bootstrap configuration itself

Advantages:
- Bootstrap state can be shared and centrally stored.
- Remote locking and versioning can also protect bootstrap state.

Disadvantages:
- The backend infrastructure becomes a prerequisite for managing itself.
- Initial provisioning and recovery require additional operational steps.
- A separate state-storage dependency must be maintained.

This is not selected for the initial implementation. The bootstrap state will remain local and must be backed up securely.

### 5. Use DynamoDB for state locking

Advantages:
- Established locking approach for earlier S3 backend configurations.

Disadvantages:
- Requires an additional AWS resource and associated permissions.
- Adds operational overhead when the native S3 lockfile mechanism is supported.

This is not selected. Terraform's native S3 lockfile mechanism will be used.

## Consequences

### Benefits

- Provides a reproducible, separately managed backend bootstrap process.
- Enables shared environment state with native state locking.
- Improves recovery options through S3 versioning.
- Establishes encryption, public-access blocking, and secure transport controls.
- Preserves local initialization and validation without remote infrastructure.
- Keeps environment state isolated through separate object keys.

### Costs and limitations

- Bootstrap provisioning requires AWS permissions and a globally unique S3 bucket name.
- Bootstrap state remains a local operational responsibility and requires secure backup.
- Remote operation requires appropriate S3 permissions and access to the configured AWS account.
- State migration and recovery require careful coordination and explicit approval.
- S3 versioning improves recovery but does not replace a documented backup and restoration procedure.
- SSE-S3 provides server-side encryption but does not provide a customer-managed KMS key.

## Implementation

The decision affects:

- `bootstrap/terraform-state/` — standalone backend bootstrap root.
- `environments/development/` — S3 backend declaration and partial backend configuration.
- `.gitignore` — exclusion of local backend configuration and sensitive local artifacts.
- `.github/workflows/terraform.ci.yml` — backend-disabled initialization and validation of bootstrap and development roots.
- `README.md` — local and remote initialization workflows.
- `doc/ARCHITECTURE.md` — state and bootstrap architecture.
- `doc/SECURITY.md` — state security, permissions, and recovery controls.
- `doc/runbooks/` — bootstrap, migration, and recovery procedures.
- `doc/ROADMAP.md` — Iteration 7 scope and acceptance criteria.

The implementation must be formatted, validated, reviewed, and tested without applying infrastructure unless separately authorized.

## References

- [Terraform S3 backend documentation](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Terraform backend configuration](https://developer.hashicorp.com/terraform/language/backend)
- [Amazon S3 user guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
- [Amazon S3 security best practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- ADR-0004: Modular Architecture and Environment Isolation
- `doc/ROADMAP.md`