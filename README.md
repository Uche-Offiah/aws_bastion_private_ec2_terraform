# AWS Bastion and Private EC2 with Terraform

A hands-on AWS networking and infrastructure-as-code proof of concept (POC) that demonstrates network segmentation, controlled SSH access, and private EC2 isolation using Terraform.

## Project Goals

- Build a dedicated VPC with public and private subnets.
- Restrict administrative SSH access through a bastion host.
- Keep the private EC2 instance without a public IP address.
- Apply least-privilege network access and defense-in-depth principles.
- Establish a foundation for exploring network security, scalability, and operational practices.
- Demonstrate reusable Terraform modules and environment-specific infrastructure configuration.

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

**Important:** The example administrator CIDR and EC2 key pair name are documentation-only placeholders. Replace them with approved values before any deployment. Confirm that the EC2 key pair exists in the selected AWS region and that the authorized administrator has access to its private key.

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
- AWS provider `~> 6.0`

The development environment includes a committed `.terraform.lock.hcl` file to maintain consistent provider selection.

## Terraform Configuration Architecture

The repository separates environment-specific configuration from reusable infrastructure modules.

```text
.
├── environments/
│   └── development/
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

### Environment root

`environments/development/` is the Terraform root for the development environment.

It is responsible for:

- AWS provider configuration and region selection.
- Environment-specific variables and configuration.
- Composing the reusable Terraform modules.
- Applying project, environment, and management default tags.
- Exposing infrastructure outputs.
- Maintaining an independent Terraform state for the environment.

### Reusable modules

| Module | Responsibility |
|---|---|
| `networking` | VPC, subnets, Internet Gateway, route tables, and routing |
| `security` | Bastion and private instance security groups and access rules |
| `compute` | Amazon Linux 2023 AMI lookup and EC2 instances |
| `flow-logs` | CloudWatch Log Group, IAM permissions, and VPC Flow Logs |

Each module has its own inputs, outputs, and provider requirements. The environment root composes the modules and passes the necessary resource references between them.

### Environment isolation and state

Each environment has its own Terraform root directory and independent local state.

Terraform commands must be executed from the relevant environment directory.

The current development configuration uses local state. Remote state using Amazon S3 is deferred to Iteration 7.

Future environments can follow the same modular structure without requiring the infrastructure modules to be duplicated. Additional environment configurations will be introduced when their requirements and configuration values are defined.

## Configuration

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

The local `terraform.tfvars` file is ignored by Git and must not be committed. Do not commit state files, saved plans, or other files containing sensitive information.

## Validate and Plan

Terraform commands must be executed from the development environment directory.

### 1. Enter the development environment

From the repository root:

```bash
cd environments/development
```

### 2. Initialize Terraform

Initialize the environment using its committed provider lock file:

```bash
terraform init -lockfile=readonly
```

### 3. Validate the configuration

```bash
terraform validate
```

### 4. Check formatting

Run the formatting check from the repository root:

```bash
terraform fmt -check -recursive
```

Open a second Git Bash terminal at the repository root to run the formatting check, or return to the repository root before executing it.

### 5. Verify the AWS identity

Before planning, verify the AWS identity and region you intend to use:

```bash
aws sts get-caller-identity
aws configure get region
```

Confirm the AWS account ID and region. The AWS CLI region may differ from the Terraform provider region, which is controlled by `aws_region` in the development environment configuration.

### 6. Generate and review a Terraform plan

Generate a saved plan:

```bash
terraform plan -out=development.tfplan
```

Inspect the resulting plan:

```bash
terraform show -no-color development.tfplan
```

Review all proposed additions, changes, and deletions, especially:

- VPCs, subnets, Internet Gateways, and route tables.
- Security groups and ingress/egress rules.
- IAM roles and permissions.
- EC2 instances and EBS volumes.
- CloudWatch Log Groups and VPC Flow Logs.

Investigate unexpected changes before proceeding, particularly when working in a shared AWS account.

The saved plan may contain sensitive information. Do not commit it or share it through unapproved channels. The repository's `.gitignore` excludes saved plan files.

**Planning does not authorize deployment. Do not run `terraform apply` without explicit approval.**

No AWS deployment is required as part of Iteration 6.

If deployment is explicitly approved, follow the [Terraform Deployment Runbook](doc/runbooks/terraform-deployment.md).

## CI and Quality Checks

The GitHub Actions workflow is located at:

`.github/workflows/terraform.ci.yml`

The workflow performs the following checks:

- Terraform formatting validation.
- Development environment initialization without a remote backend.
- Development environment configuration validation.
- Checkov Terraform security scanning.

The current workflow uses `soft_fail: true` for Checkov, so security findings are reported but do not fail the workflow.

The development environment is the current environment root validated by Terraform CI. Checkov scans the repository. Additional environment roots can be incorporated into Terraform validation as they are introduced.

## Project Status

The project is being developed through versioned iterations.

- **Iteration 3:** Established the enterprise Infrastructure-as-Code baseline.
- **Iteration 4:** Completed the documentation and operational-readiness review.
- **Iteration 5:** Established the local-ready release baseline.
- **Iteration 6:** Introduces modular Terraform architecture and environment separation, with the development environment implemented first.
- **Iteration 7:** Planned introduction of remote state using Amazon S3.

The Terraform configuration has not been deployed as part of this development workflow. Documented controls describe the configuration and intended design; they must not be interpreted as verification of controls on running AWS resources.

VPC Flow Logs are configured to capture all traffic and send records to CloudWatch Logs with configurable retention. Detailed EC2 monitoring is enabled and may incur additional charges. These controls do not, by themselves, provide a complete alerting, incident-response, or recovery capability.

## Documentation

### Architecture and security

- [Architecture Overview](doc/ARCHITECTURE.md) — network layout, components, and traffic flows.
- [Security Design](doc/SECURITY.md) — security controls, assumptions, limitations, and deferred work.
- [Project Roadmap](doc/ROADMAP.md) — implementation iterations, scope, and acceptance criteria.

### Architecture Decision Records

- [ADR-0001: VPC CIDR Allocation](doc/adr/0001-network-cidr-allocation.md)
- [ADR-0002: Bastion-Based SSH Access](doc/adr/0002-bastion-ssh-access.md)
- [ADR-0003: Private Instance Isolation](doc/adr/0003-private-instance-isolation.md)
- [ADR-0004: Modular Architecture and Environment Isolation](doc/adr/0004-modular-architecture-and-environment-isolation.md)
- [ADR Template](doc/adr/0000-template.md)

### Operational runbooks

- [Terraform Deployment](doc/runbooks/terraform-deployment.md)
- [Terraform Destruction](doc/runbooks/terraform-destruction.md)
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
- Any additional network services introduced in future iterations.

Do not destroy resources until the Terraform destruction plan has been reviewed and the required approval obtained.

See the [Terraform Destruction Runbook](doc/runbooks/terraform-destruction.md).

## License

No license has been specified for this repository yet.