# AWS Bastion and Private EC2 Infrastructure

## Overview

This project uses Terraform to provision a dedicated AWS network containing a public bastion host and a private EC2 instance.

The architecture is designed to demonstrate secure network segmentation, controlled administrative access, and infrastructure provisioning using Infrastructure as Code (IaC).

## Architecture

The initial architecture includes:

- A dedicated VPC using `10.20.0.0/16`.
- A public subnet for the bastion host.
- A private subnet for the private EC2 instance.
- An Internet Gateway and public route table for internet connectivity to the public subnet.
- A private route table without a default internet route.
- Security groups that restrict SSH access to the approved administrator CIDR and the bastion host.
- Amazon Linux 2023 EC2 instances.
- Encrypted root EBS volumes and IMDSv2 enforcement.
- Terraform-managed resource tags.

## Technology Stack

- AWS
- Terraform
- AWS CLI
- Git and GitHub

## Prerequisites

Before deploying the infrastructure, ensure you have:

- Terraform installed.
- AWS CLI installed and configured with the intended AWS account and region.
- Appropriate AWS permissions.
- An existing EC2 key pair in the selected region.
- An approved public IPv4 CIDR for administrator SSH access.

## Configuration

Set the required variables in a local `terraform.tfvars` file, including:

- `admin_cidr`
- `key_pair_name`

Review the variable definitions in `variables.tf` for defaults and other configurable settings.

Do not commit real `terraform.tfvars` files, private keys, credentials, or other secrets.

## Validation

Initialize the Terraform working directory:

```bash
terraform init
```

Format and validate the configuration:

```bash
terraform fmt -check -recursive
terraform validate
```

Review the proposed infrastructure changes:

```bash
terraform plan
```

**Do not apply the plan until the proposed changes have been reviewed and explicitly approved.**

## Project Status

The project is being developed iteratively. Each iteration introduces a cohesive set of changes, validated and documented before being merged into the integration branch and tagged.

The initial milestone focuses on the network foundation, security groups, and bastion/private EC2 infrastructure.

## Cost and Cleanup

AWS resources may incur charges when deployed. Review the expected costs before deployment and ensure resources are safely destroyed when no longer required.

Only run `terraform destroy` after reviewing its plan and confirming that the resources are safe to remove.

## Security Considerations

- Restrict administrator SSH access to an approved CIDR.
- Never expose the private EC2 instance directly to the public internet.
- Keep Terraform state and sensitive configuration out of version control.
- Review security group rules and Terraform plans before deployment.
- Treat this project as an evolving learning architecture, not a production-ready security baseline until the remaining hardening and operational work is completed.
