# AWS Bastion and Private EC2 with Terraform

A hands-on AWS networking and infrastructure-as-code proof of concept (POC) that demonstrates network segmentation, controlled SSH access, and private EC2 isolation using Terraform.

## Project Goals

- Build a dedicated VPC with public and private subnets.
- Restrict administrative SSH access through a bastion host.
- Keep the private EC2 instance without a public IP address.
- Apply least-privilege network access and defense-in-depth principles.
- Establish a foundation for exploring network security, scalability, and operational practices.

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

See [Architecture Overview](doc/ARCHITECTURE.md) for the detailed design and traffic flows.

## Security Controls

The current Terraform configuration includes:

- SSH ingress restricted to the configured administrator CIDR on the bastion.
- SSH ingress to the private instance restricted to the bastion security group.
- No public IP address on the private instance.
- IMDSv2 required for both EC2 instances.
- Encrypted `gp3` root EBS volumes.
- EC2 API termination protection enabled.
- No explicitly configured security-group egress rules other than the required bastion-to-private SSH rule.

**Important:** The example administrator CIDR is documentation-only. Replace it with an approved public IPv4 CIDR before any deployment. Confirm that the EC2 key pair exists in the selected AWS region and that the authorized administrator has access to its private key.

See [Security Design](doc/SECURITY.md) for security assumptions, limitations, and deferred decisions.

## Prerequisites

Install and configure:

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- An AWS identity authorized to inspect and manage the intended resources.
- An existing EC2 key pair in the selected AWS region.
- An approved administrator public IPv4 CIDR.

The Terraform configuration uses the AWS provider `~> 6.0` and requires Terraform `>= 1.10.0, < 2.0.0`.

## Configuration

Review `variable.tf` and `terraform.tfvars.example` before configuring the project.

Create your local variable file from the tracked example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and replace the documentation-only values:

- `admin_cidr`: use an approved public IPv4 CIDR for the administrator who will access the bastion. Do not use the example documentation address.
- `key_pair_name`: use the name of an existing EC2 key pair in the selected AWS region.
- `aws_region`: set this explicitly if you intend to use a region other than the configured default.

Review any other required variables in `variable.tf`. The local `terraform.tfvars` file is ignored by Git and must not be committed.

## Validate and Plan

Run these commands from the repository root.

First, initialize the local Terraform working directory:

```bash
terraform init
```

Then check formatting and configuration validity:

```bash
terraform fmt -check -recursive
terraform validate
```

Before planning, verify the AWS identity you intend to use:

```bash
aws sts get-caller-identity
aws configure get region
```

Confirm the account ID and region. The AWS CLI region may differ from the Terraform provider region, which is controlled by `aws_region`.

Generate a saved plan for review:

```bash
terraform plan -out=tfplan
terraform show -no-color tfplan
```

Review all proposed additions, changes, and deletions, especially networking, security groups, IAM permissions, EC2 instances, and EBS resources in a shared AWS account. Investigate any unexpected changes before proceeding.

The saved plan may contain sensitive information. Do not commit it or share it through unapproved channels. The repository's `.gitignore` excludes saved plan files.

**Planning does not authorize deployment. Do not run `terraform apply` without explicit approval.** No AWS deployment is required for this local-ready release.

If deployment is approved, follow the [Terraform Deployment Runbook](doc/runbooks/terraform-deployment.md).

## Project Status

The project is being developed through versioned iterations. Iterations 3 and 4 established the enterprise-IaC baseline and completed the documentation and operational-readiness review. Iteration 5 focuses on local-ready verification and release.

The Terraform configuration has not been deployed as part of this workflow. Documented controls describe the configuration and intended design; they must not be interpreted as verification of controls on running AWS resources.

VPC Flow Logs are configured to capture all traffic and send records to CloudWatch Logs with configurable retention. Detailed EC2 monitoring is enabled and may incur additional charges. These controls do not, by themselves, provide a complete alerting, incident-response, or recovery capability.

## Documentation

### Architecture and security

- [Architecture Overview](doc/ARCHITECTURE.md) — network layout, components, and traffic flows.
- [Security Design](doc/SECURITY.md) — security controls, assumptions, limitations, and deferred work.

### Architecture Decision Records

- [ADR-0001: VPC CIDR Allocation](doc/adr/0001-network-cidr-allocation.md)
- [ADR-0002: Bastion-Based SSH Access](doc/adr/0002-bastion-ssh-access.md)
- [ADR-0003: Private Instance Isolation](doc/adr/0003-private-instance-isolation.md)
- [ADR Template](doc/adr/0000-template.md)

### Operational runbooks

- [Terraform Deployment](doc/runbooks/terraform-deployment.md)
- [Terraform Destruction](doc/runbooks/terraform-destruction.md)
- [Bastion Access Troubleshooting](doc/runbooks/bastion-access-troubleshooting.md)
- [VPC Flow Logs Troubleshooting](doc/runbooks/vpc-flow-logs-troubleshooting.md)

## Cost and Cleanup Considerations

No AWS resources have been created through this workflow. If the configuration is deployed later, review expected charges before applying it.

Potential costs include EC2 instance usage, EBS storage, public IPv4 addresses, and any additional network services introduced in future iterations.

Do not destroy resources until the Terraform destruction plan has been reviewed and the required approval obtained. See the [Terraform Destruction Runbook](doc/runbooks/terraform-destruction.md).

## License

No license has been specified for this repository yet.