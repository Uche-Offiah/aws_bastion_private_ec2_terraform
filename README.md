# AWS Bastion and Private EC2 with Terraform

A hands-on AWS networking and infrastructure-as-code proof of concept (POC) that demonstrates network segmentation, controlled SSH access, and private EC2 isolation using Terraform.

## Project Goals

- Build a dedicated VPC with public and private subnets.
- Restrict administrative SSH access through a bastion host.
- Keep the private EC2 instance without a public IP address.
- Apply least-privilege network access and defense-in-depth principles.
- Establish a foundation for exploring network security, scalability, and operational practices.
- Demonstrate reusable Terraform modules and environment-specific infrastructure configuration.
- Establish a secure and recoverable remote Terraform state architecture using Amazon S3.

## Architecture

The project uses a dedicated VPC with a public subnet for the bastion and a private subnet for the private EC2 instance.

| Component | CIDR / Configuration | Purpose |
|---|---|---|
| VPC | `10.20.0.0/16` | Dedicated project network |
| Public subnet | `10.20.1.0/24` | Bastion host |
| Private subnet | `10.20.2.0/24` | Private EC2 workload |
| Internet Gateway | Attached to the VPC | Internet connectivity path for the public subnet |
| Bastion ingress | TCP 22 from `admin_cidr` | Restricted administrator access |
| Private ingress | TCP 22 from bastion security group | Controlled SSH to private infrastructure |
| VPC Flow Logs | All traffic | Network traffic visibility through CloudWatch Logs |

The private subnet has no internet default route. No NAT Gateway or VPC endpoints are currently configured.

The intended administrative path is:

```text
Administrator workstation
        |
        | SSH (TCP 22)
        v
Public bastion EC2
        |
        | SSH (TCP 22)
        v
Private EC2
```

The infrastructure is organized into reusable Terraform modules, composed by an environment-specific root configuration.

See [Architecture Overview](doc/ARCHITECTURE.md) for the detailed design and traffic flows.

## Security Controls

The Terraform configuration includes:

- SSH ingress restricted to the configured administrator CIDR on the bastion.
- SSH ingress to the private instance restricted to the bastion security group.
- No public IP address on the private instance.
- No explicitly configured security-group egress rules other than the required bastion-to-private SSH rule.
- IMDSv2 required for both EC2 instances.
- Encrypted `gp3` root EBS volumes.
- EC2 API termination protection enabled.
- VPC Flow Logs configured to capture all traffic.
- CloudWatch Logs retention configured through a Terraform variable.
- IAM trust policy conditions restricting the VPC Flow Logs service role.

The Terraform state architecture also defines the following intended controls for the S3 state bucket:

- S3 bucket versioning.
- Server-side encryption using SSE-S3.
- S3 Block Public Access.
- Bucket ownership enforced through `BucketOwnerEnforced`.
- Bucket policy denying requests that do not use HTTPS.
- Native S3 lockfile-based state locking.

**Important:** The example administrator CIDR and EC2 key pair name are documentation-only placeholders. Replace them with approved values before any deployment. Confirm that the EC2 key pair exists in the selected AWS region and that the authorized administrator has access to its private key.

The S3 controls describe the Terraform bootstrap configuration. They must not be interpreted as verified controls on a provisioned bucket until the bootstrap infrastructure has been deployed and independently checked.

See [Security Design](doc/SECURITY.md) for security assumptions, limitations, and deferred decisions.

## Prerequisites

Install and configure:

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- An AWS identity authorized to inspect and manage the intended resources.
- An existing EC2 key pair in the selected AWS region.
- An approved administrator public IPv4 CIDR.

The Terraform configuration requires:

- Terraform `>= 1.10.0, < 2.0.0`
- AWS provider `= 6.72.0` in the bootstrap and development root configurations.
- Reusable modules declare their own compatible AWS provider requirements.

The root configurations include committed `.terraform.lock.hcl` files to maintain consistent provider selection. Do not manually edit provider lockfile entries. Update provider selections through Terraform and review the resulting lockfile changes.

## Terraform Configuration Architecture

The repository separates environment-specific configuration, reusable infrastructure modules, and Terraform state bootstrap configuration.

```text
.
├── bootstrap/
│   └── terraform-state/
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── variables.tf
│       ├── versions.tf
│       ├── terraform.tfvars.example
│       └── .terraform.lock.hcl
│
├── environments/
│   └── development/
│       ├── backend.tf
│       ├── backend.hcl.example
│       ├── main.tf
│       ├── provider.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── terraform.tfvars.example
│       └── .terraform.lock.hcl
│
├── modules/
│   ├── networking/
│   ├── security/
│   ├── compute/
│   └── flow-logs/
│
├── doc/
│   ├── adr/
│   ├── runbooks/
│   ├── ARCHITECTURE.md
│   ├── SECURITY.md
│   └── ROADMAP.md
│
└── .github/
    └── workflows/
        └── terraform.ci.yml
```

### Bootstrap root

`bootstrap/terraform-state/` is a separate Terraform root responsible for creating the S3 bucket intended to store remote Terraform state.

The bootstrap configuration defines:

- A required, globally unique S3 bucket name.
- S3 bucket versioning.
- SSE-S3 server-side encryption.
- S3 Block Public Access.
- Bucket ownership controls using `BucketOwnerEnforced`.
- A bucket policy denying non-TLS requests.
- `prevent_destroy = true` and `force_destroy = false`.
- Project, environment, and management tags.

The bootstrap root uses local Terraform state. Its state must remain separate from the S3 bucket it creates. Protect and back up the bootstrap state securely because it is required to manage the state bucket itself.

The bootstrap configuration is intentionally independent of the development environment backend. This avoids a circular dependency in which the configuration responsible for creating the remote state bucket would itself depend on that bucket.

### Environment root

`environments/development/` is the Terraform root for the development environment.

It is responsible for:

- AWS provider configuration and region selection.
- Environment-specific variables and configuration.
- Composing the reusable Terraform modules.
- Applying project, environment, and management default tags.
- Exposing infrastructure outputs.
- Maintaining an independent Terraform state for the environment.

The development root declares an S3 backend in `backend.tf`. Backend settings are supplied separately through a local `backend.hcl` file, which is not committed to Git.

The tracked `backend.hcl.example` file documents the required backend configuration without containing a real bucket name.

### Reusable modules

| Module | Responsibility |
|---|---|
| `networking` | VPC, subnets, Internet Gateway, route tables, and routing |
| `security` | Bastion and private instance security groups and access rules |
| `compute` | Amazon Linux 2023 AMI lookup and EC2 instances |
| `flow-logs` | CloudWatch Log Group, IAM permissions, and VPC Flow Logs |

Each module has its own inputs, outputs, and provider requirements. The environment root composes the modules and passes the necessary resource references between them.

### Environment isolation and state

Each environment has its own Terraform root directory and independent state.

The intended state architecture separates bootstrap state from environment state:

| Terraform root | Backend | State responsibility |
|---|---|---|
| `bootstrap/terraform-state/` | Local | Manages the S3 bucket used for remote state |
| `environments/development/` | Amazon S3 | Manages development environment infrastructure |

The development environment uses the following S3 state key:

```text
environments/development/terraform.tfstate
```

The development backend uses native S3 lockfile-based locking through `use_lockfile = true`. DynamoDB-based locking is not part of this design.

The actual `backend.hcl` file is local configuration and must not be committed. The `.gitignore` file excludes it.

**Current operational status:** The bootstrap and development backend configurations have been implemented, but the S3 bucket has not been provisioned and the development state has not been migrated to S3. Backend initialization, state migration, and live remote-state verification remain separate operational steps requiring explicit approval.

Future environments can follow the same modular structure and use independent state keys without duplicating the infrastructure modules.

## Configuration

### Development environment variables

The development environment provides a tracked example variable file:

`environments/development/terraform.tfvars.example`

From the repository root, create your local variable file:

```bash
cp environments/development/terraform.tfvars.example environments/development/terraform.tfvars
```

Edit `environments/development/terraform.tfvars` and replace the documentation-only values:

- `admin_cidr`: use an approved public IPv4 CIDR for the administrator who will access the bastion.
- `key_pair_name`: use the name of an existing EC2 key pair in the selected AWS region.
- `aws_region`: change the configured default only if you intend to use another region.

Review `environments/development/variables.tf` for the complete variable definitions, defaults, and validation rules.

**Do not use the example administrator CIDR or key pair name for an actual deployment.** Both values must be verified and approved before deployment.

### Bootstrap configuration

The bootstrap root provides a tracked example variable file:

`bootstrap/terraform-state/terraform.tfvars.example`

Before any approved bootstrap deployment, create a local variable file:

```bash
cp bootstrap/terraform-state/terraform.tfvars.example bootstrap/terraform-state/terraform.tfvars
```

Set `state_bucket_name` to a globally unique bucket name approved for this project. Review the bootstrap variables and resource configuration before any deployment.

The bootstrap root's local state is independent of the development environment state. Keep its state file secure and maintain a separate backup.

### Development backend configuration

The development root provides a tracked backend configuration template:

`environments/development/backend.hcl.example`

The template contains a placeholder bucket name. The actual local configuration file is:

`environments/development/backend.hcl`

The actual file must contain the approved S3 bucket name and must not be committed. It is excluded by `.gitignore`.

Do not initialize or migrate the development environment to the S3 backend until the bucket has been provisioned, its configuration has been verified, and the operation has received explicit approval.

### Sensitive and local files

Local `terraform.tfvars`, `backend.hcl`, Terraform state files, saved plans, and other files containing sensitive information must not be committed.

## Validate and Plan

Terraform configuration validation can be performed without provisioning AWS resources or initializing the remote backend.

Run the following commands from the repository root.

### 1. Initialize and validate the bootstrap root

```bash
terraform -chdir=bootstrap/terraform-state init -backend=false -lockfile=readonly
terraform -chdir=bootstrap/terraform-state validate
```

The `-backend=false` option keeps this validation workflow independent of the remote S3 backend.

### 2. Initialize and validate the development root

```bash
terraform -chdir=environments/development init -backend=false -lockfile=readonly
terraform -chdir=environments/development validate
```

This performs local configuration validation without connecting to the configured S3 backend.

### 3. Check formatting

Run the formatting check from the repository root:

```bash
terraform fmt -check -recursive
```

### 4. Verify the AWS identity

Before any approved AWS operation, verify the AWS identity and region you intend to use:

```bash
aws sts get-caller-identity
aws configure get region
```

Confirm the AWS account ID and region. The AWS CLI region may differ from the Terraform provider region, which is controlled by `aws_region` in the relevant Terraform root configuration.

### 5. Plan and deployment safeguards

A Terraform plan must be generated and reviewed against the correct backend and state before any deployment is considered.

For the development environment, this requires the S3 state bucket to be provisioned, the backend configuration to be populated with the approved bucket name, and the remote backend to be initialized through an approved operational procedure.

Review all proposed additions, changes, and deletions, especially:

- VPCs, subnets, Internet Gateways, and route tables.
- Security groups and ingress/egress rules.
- IAM roles and permissions.
- EC2 instances and EBS volumes.
- CloudWatch Log Groups and VPC Flow Logs.

Investigate unexpected changes before proceeding, particularly when working in a shared AWS account.

Saved plans and Terraform state may contain sensitive information. Do not commit them or share them through unapproved channels. The repository's `.gitignore` excludes local Terraform state, backend configuration, and saved plan files.

**Planning does not authorize deployment. Do not run `terraform apply` without explicit approval.**

No AWS deployment or remote state migration is required to complete local configuration validation.

If deployment is explicitly approved, follow the [Terraform Deployment Runbook](doc/runbooks/terraform-deployment.md).

## CI and Quality Checks

The GitHub Actions workflow is located at:

`.github/workflows/terraform.ci.yml`

The current workflow performs the following checks:

- Terraform formatting validation.
- Development environment initialization without a remote backend.
- Development environment configuration validation.
- Checkov Terraform security scanning.

The current workflow uses `soft_fail: true` for Checkov, so security findings are reported but do not fail the workflow.

The development environment is the current environment root validated by Terraform CI. Checkov scans the repository.

The bootstrap root has been added as a separate Terraform root. CI validation for both the bootstrap and development roots is a remaining Iteration 7 quality-check task.

CI validation must remain independent of live AWS backend initialization and must not provision infrastructure.

## Project Status

The project is being developed through versioned iterations.

- **Iteration 3:** Established the enterprise Infrastructure-as-Code baseline.
- **Iteration 4:** Completed the documentation and operational-readiness review.
- **Iteration 5:** Established the local-ready release baseline.
- **Iteration 6:** Introduced modular Terraform architecture and environment separation, with the development environment implemented first.
- **Iteration 7:** Introduces secure and recoverable remote Terraform state using Amazon S3.

Iteration 7 implementation includes:

- A separate Terraform bootstrap root for the S3 state bucket.
- S3 versioning, SSE-S3 encryption, public-access blocking, and HTTPS-only bucket access in the bootstrap configuration.
- Native S3 lockfile-based locking for the development backend.
- Exact AWS provider version alignment across the bootstrap and development roots.
- A separate development state key.
- Local backend configuration kept outside version control.
- State bootstrap, migration, and recovery documentation.

Remaining Iteration 7 work includes CI validation of both Terraform roots, final documentation verification, and the separately approved operational provisioning and verification of the remote state infrastructure.

The Terraform configuration has not been deployed as part of this development workflow. The S3 state bucket has not been provisioned through this workflow, and the development state has not been migrated to it. Documented controls describe the configuration and intended design; they must not be interpreted as verification of controls on running AWS resources.

VPC Flow Logs are configured to capture all traffic and send records to CloudWatch Logs with configurable retention. Detailed EC2 monitoring is enabled and may incur additional charges. These controls do not, by themselves, provide a complete alerting, incident-response, or recovery capability.

## Documentation

### Architecture and security

- [Architecture Overview](doc/ARCHITECTURE.md) — network layout, components, traffic flows, and Terraform state architecture.
- [Security Design](doc/SECURITY.md) — security controls, assumptions, limitations, and deferred work.
- [Project Roadmap](doc/ROADMAP.md) — implementation iterations, scope, and acceptance criteria.

### Architecture Decision Records

- [ADR-0001: VPC CIDR Allocation](doc/adr/0001-network-cidr-allocation.md)
- [ADR-0002: Bastion-Based SSH Access](doc/adr/0002-bastion-ssh-access.md)
- [ADR-0003: Private Instance Isolation](doc/adr/0003-private-instance-isolation.md)
- [ADR-0004: Modular Architecture and Environment Isolation](doc/adr/0004-modular-architecture-and-environment-isolation.md)
- [ADR-0005: S3 Remote State Architecture](doc/adr/0005-s3-remote-state-architecture.md)
- [ADR Template](doc/adr/0000-template.md)

### Operational runbooks

- [Terraform Deployment](doc/runbooks/terraform-deployment.md)
- [Terraform Destruction](doc/runbooks/terraform-destruction.md)
- [Terraform State Bootstrap](doc/runbooks/terraform-state-bootstrap.md)
- [Terraform State Migration](doc/runbooks/terraform-state-migration.md)
- [Terraform State Recovery](doc/runbooks/terraform-state-recovery.md)
- [Bastion Access Troubleshooting](doc/runbooks/bastion-access-troubleshooting.md)
- [VPC Flow Logs Troubleshooting](doc/runbooks/vpc-flow-logs-troubleshooting.md)

## Cost and Cleanup Considerations

No AWS resources have been created through this development workflow. If the configuration is deployed later, review expected charges before applying it.

Potential costs include:

- EC2 instance usage.
- EBS storage.
- Public IPv4 addresses.
- CloudWatch Logs ingestion and storage.
- Detailed EC2 monitoring.
- S3 storage and requests for Terraform state and its versions.
- Any additional network services introduced in future iterations.

S3 versioning retains previous state object versions and can increase storage costs. Review the bucket's version-retention and recovery requirements before introducing lifecycle policies.

Do not destroy resources until the Terraform destruction plan has been reviewed and the required approval obtained.

See the [Terraform Destruction Runbook](doc/runbooks/terraform-destruction.md).

## License

No license has been specified for this repository yet.