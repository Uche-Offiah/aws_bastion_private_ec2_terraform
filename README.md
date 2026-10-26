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

Review `variable.tf` and `terraform.tfvars.example` to understand the configurable inputs.

Create a local `terraform.tfvars` file based on the example:

```hcl
aws_region     = "us-east-2"
admin_cidr     = "REPLACE_WITH_APPROVED_PUBLIC_IPV4_CIDR"
key_pair_name  = "REPLACE_WITH_EXISTING_EC2_KEY_PAIR_NAME"
```

The example above illustrates the main deployment-specific values; retain or add any other required variables from `terraform.tfvars.example`.

Do not commit `terraform.tfvars`, private keys, Terraform state files, or saved plan files.

## Validate and Plan

Run these commands from the repository root:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform show -no-color tfplan
```

Review the plan carefully for unexpected resource changes, particularly in a shared AWS account.

Check the AWS identity and intended region before planning:

```bash
aws sts get-caller-identity
aws configure get region
```

The AWS CLI region may differ from the Terraform provider region, so confirm both.

**Do not apply a plan without explicit approval.** This repository's current workflow does not require deployment to complete the POC's documentation and review milestones.

If deployment is approved, follow the [Terraform Deployment Runbook](doc/runbooks/terraform-deployment.md).

## Project Status

This project is being developed iteratively. The initial network foundation is documented, and the current hardening iteration includes security controls, architecture decisions, and operational documentation.

The infrastructure has not been deployed as part of this workflow. Documented controls therefore describe the Terraform configuration and intended design, not independently verified controls on running AWS resources.

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

## Cost and Cleanup Considerations

No AWS resources have been created through this workflow. If the configuration is deployed later, review expected charges before applying it.

Potential costs include EC2 instance usage, EBS storage, public IPv4 addresses, and any additional network services introduced in future iterations.

Do not destroy resources until the Terraform destruction plan has been reviewed and the required approval obtained. See the [Terraform Destruction Runbook](doc/runbooks/terraform-destruction.md).

## License

No license has been specified for this repository yet.