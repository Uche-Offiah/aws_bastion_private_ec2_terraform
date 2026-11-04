# ADR-0004: Modular Architecture and Environment Isolation

- **Status:** Accepted
- **Date:** 2026-11-02
- **Decision Owners:** Project maintainers
- **Related Iteration:** Iteration 6 – Modular Environment Architecture
- **Related ADRs:**
  - ADR-0001: Network CIDR Allocation
  - ADR-0002: Bastion SSH Access
  - ADR-0003: Private Instance Isolation

## 1. Context

The initial implementation of the AWS Bastion and Private EC2 infrastructure was developed using a root-level Terraform configuration.

As the project evolves, maintaining all infrastructure resources within a single configuration becomes increasingly difficult to manage, extend, and reuse.

The project also needs a clear separation between environments to prevent configuration and state from different environments from being unintentionally mixed.

The architecture must support:

- Reusable infrastructure components.
- Clear separation of infrastructure responsibilities.
- Independent environment configurations.
- Isolated Terraform state for each environment.
- Consistent security and infrastructure standards.
- Future expansion without unnecessary duplication.

The existing infrastructure design and security decisions documented in ADR-0001, ADR-0002, and ADR-0003 must remain unchanged unless a separate architecture decision explicitly approves a modification.

## 2. Decision

The project will adopt a modular Terraform architecture with separate environment root configurations.

Infrastructure resources will be organized into reusable Terraform modules, while environment-specific configurations will compose and configure those modules.

Development will be the first implemented environment. Additional environments may be introduced as their requirements become defined.

### 2.1 Module boundaries

The infrastructure will be divided into the following modules:

**Networking module**

Responsible for:
- VPC creation.
- Default security group configuration.
- Internet Gateway.
- Public and private subnets.
- Public and private route tables.
- Internet routing and route table associations.

**Security module**

Responsible for:
- Bastion security group.
- Private EC2 security group.
- Bastion SSH ingress rule.
- Private EC2 SSH ingress rule.
- Bastion-to-private SSH egress rule.

**Compute module**

Responsible for:
- Amazon Linux 2023 AMI lookup.
- Bastion EC2 instance.
- Private EC2 instance.
- EC2 instance configuration and associated storage settings.

**Flow Logs module**

Responsible for:
- CloudWatch Log Group.
- IAM role and associated policy for VPC Flow Logs.
- VPC Flow Logs configuration.

Each module must expose the inputs and outputs required for integration with other modules without unnecessarily exposing its internal implementation.

### 2.2 Environment configuration

Environment-specific Terraform configurations will reside under the `environments/` directory.

The initial implementation will include:

`environments/development/`

Each environment root will:
- Configure its AWS provider and region.
- Define environment-specific input variables.
- Compose the reusable infrastructure modules.
- Supply environment-specific configuration values.
- Expose relevant infrastructure outputs.
- Maintain the Terraform dependency lock file in the environment root directory and commit it to version control.

Child modules will inherit the provider configuration from the calling environment root.

Provider-level default tags will remain centrally configured in the environment root.

Additional environments will follow the same structure when their requirements and configuration values are defined.

### 2.3 Terraform state isolation

Each environment will maintain its own independent Terraform state, stored locally in its environment root directory during Iteration 6.

Terraform operations must be executed from the relevant environment directory. Each environment must be initialized and managed independently, with no shared state file between environments.

Terraform workspaces will not be used as the primary environment isolation mechanism.

State files, backup state files, and generated plan files must not be committed to version control.

Remote state management using Amazon S3 is explicitly deferred to Iteration 7.

### 2.4 Backend configuration

No remote backend will be introduced as part of this iteration.

The development environment will use Terraform's default local backend.

The architecture must remain compatible with a future transition to S3-backed remote state without requiring changes to the module boundaries.

## 3. Consequences

### 3.1 Positive consequences

- Infrastructure responsibilities become easier to understand and maintain.
- Modules can be reused across future environments.
- Environment-specific configurations become independently manageable.
- Terraform state is separated between environments.
- Changes to individual infrastructure components become easier to review.
- Future remote state implementation has a defined architectural foundation.

### 3.2 Trade-offs and considerations

- The number of Terraform files and directories will increase.
- Module interfaces must be maintained as infrastructure evolves.
- Cross-module dependencies must be explicitly managed through inputs and outputs.
- Terraform commands must be executed from the appropriate environment directory.
- CI workflows must be updated to validate all environment configurations and reusable modules.
- Changes to resource addresses during modularization must be reviewed carefully.

## 4. Existing Infrastructure and Security Decisions

Modularization must preserve the existing architecture and security decisions.

The following remain unchanged:

- VPC CIDR allocation: `10.20.0.0/16`.
- Public subnet CIDR: `10.20.1.0/24`.
- Private subnet CIDR: `10.20.2.0/24`.
- Bastion host provides the SSH entry point.
- Private EC2 instance has no public IP address.
- Private SSH access is restricted to the bastion security group.
- No NAT Gateway or private subnet default internet route.
- No VPC endpoints are introduced.
- IMDSv2 remains required.
- Root EBS volumes remain encrypted gp3 volumes.
- VPC Flow Logs continue capturing all traffic.
- CloudWatch Flow Logs retention remains 30 days.
- Existing project tagging standards remain in place.

The administrative CIDR and EC2 key pair remain deployment-specific inputs and must be verified before any future deployment.

## 5. Implementation Structure

The intended project structure is:

```text
environments/
└── development/
    ├── main.tf
    ├── provider.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    └── terraform.tfvars.example

modules/
├── networking/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── security/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/
│   ├── main.tf
│   ├── data.tf
│   ├── variables.tf
│   └── outputs.tf
└── flow-logs/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

Documentation, CI workflows, and existing repository-level configuration will remain at their appropriate repository locations.

## 6. Validation Requirements

The modular architecture must satisfy the following before the iteration is considered complete:

1. Terraform formatting checks pass.
2. Terraform initialization succeeds for the development environment.
3. Terraform validation succeeds.
4. Module inputs and outputs are correctly connected.
5. Existing security and infrastructure decisions are preserved.
6. CI validates the development environment and reusable modules.
7. Terraform plan output is reviewed for unexpected resource creation, replacement, or destruction.
8. No AWS infrastructure is deployed as part of this iteration.

## 7. Future Considerations

The following activities are outside the scope of this decision:

- S3 remote state and state locking implementation.
- Production environment configuration.
- Deployment of infrastructure to AWS.
- Introduction of additional AWS services or security capabilities.

These activities require their own implementation planning and, where appropriate, separate architecture decisions.

## 8. References

- ADR-0001: Network CIDR Allocation.
- ADR-0002: Bastion SSH Access.
- ADR-0003: Private Instance Isolation.
- `doc/ARCHITECTURE.md`
- `doc/SECURITY.md`
- `doc/ROADMAP.md`