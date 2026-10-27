# Runbook: Bastion Access Troubleshooting

## 1. Purpose

This runbook helps diagnose SSH connectivity failures between an administrator workstation, the bastion EC2 instance, and the private EC2 instance.

The troubleshooting process starts with read-only checks and avoids changing security groups, routes, or instance settings without understanding the cause.

## 2. Expected Connectivity

The intended access path is:

1. Administrator workstation → bastion public IP, using SSH over TCP port 22.
2. Bastion → private EC2 private IP, using SSH over TCP port 22.

The bastion's inbound SSH rule is restricted to the configured administrator CIDR. The private instance accepts SSH only from the bastion security group.

## 3. Troubleshooting Checklist

### Step 1: Confirm the AWS account and region

Run:

```bash
aws sts get-caller-identity
aws configure get region
```

Confirm that the AWS identity and region match the intended environment.

The AWS CLI region and Terraform provider region can differ. Check the Terraform configuration and `aws_region` variable as well.

### Step 2: Confirm the bastion instance state and addressing

In the AWS EC2 console, locate the bastion instance and check:

- The instance is running.
- The instance has passed its status checks.
- A public IPv4 address is assigned.
- The expected bastion security group is attached.
- The instance is in the intended public subnet.

If the instance is stopped, impaired, or missing a public IP, investigate that condition before attempting SSH again.

### Step 3: Verify the administrator CIDR

Confirm the public IPv4 address from which the administrator is connecting and compare it with the configured `admin_cidr` value.

The bastion security group must allow TCP port 22 from the administrator's current public IP in CIDR notation.

For a single administrator IP, this is normally a `/32` CIDR.

Do not use `0.0.0.0/0` as a troubleshooting shortcut. If the administrator's public IP changes, update the approved CIDR through the normal reviewed configuration process.

The example CIDR in `terraform.tfvars.example` is documentation-only and must not be treated as a real administrator address.

### Step 4: Check the bastion security group and routing

Verify that:

- Inbound TCP port 22 is permitted from the administrator CIDR.
- The public subnet's route table has a default route to the Internet Gateway.
- The Internet Gateway is attached to the intended VPC.
- The subnet and network ACL configuration do not block the required traffic.
- The bastion has a public IP address and a valid path for internet communication.

Security-group changes should be narrowly scoped and reviewed before implementation.

### Step 5: Test SSH to the bastion

From the administrator workstation:

```bash
ssh -i <path-to-private-key> ec2-user@<bastion-public-ip>
```

Replace the placeholders with the actual private-key path and bastion public IP.

If the connection fails, examine the SSH error:

- **Connection timed out:** Investigate routing, security groups, network ACLs, public addressing, and local network restrictions.
- **Permission denied (publickey):** Verify the username, the selected private key, and that the public key corresponds to the EC2 key pair used when launching the instance.
- **Connection refused:** Confirm that the instance is running and that SSH is listening and available on the instance.

For Amazon Linux 2023, the default SSH username is normally `ec2-user`.

Never paste or commit a private key into the repository, a ticket, or a chat.

### Step 6: Verify the private instance

After connecting to the bastion, verify the private instance in the EC2 console or through read-only AWS CLI queries.

Confirm that:

- The instance is running and has passed its status checks.
- Its private IP address is correct.
- It does not have a public IP address.
- It is attached to the expected private subnet and security group.
- The private subnet's route table has the expected local VPC route.
- The private security group permits inbound TCP port 22 from the bastion security group.
- The bastion security group's egress rule permits TCP port 22 to the private security group.

From the bastion, attempt SSH to the private instance:

```bash
ssh -i <path-to-private-key> ec2-user@<private-instance-ip>
```

This command assumes the private key is securely available on the bastion. Prefer a securely managed access method or SSH agent forwarding rather than copying private keys onto the bastion. If the key is not available there, use an approved alternative that keeps the private key on the administrator workstation.

If SSH times out, investigate security-group rules, subnet routing, network ACLs, and SSH availability on the private instance.

If SSH returns `Permission denied (publickey)`, verify the username and key authorization.

### Step 7: Review the intentional connectivity restrictions

The private instance has no internet default route and no explicitly configured security-group egress rules.

Therefore, package downloads, general internet access, and some AWS service connections are not available through the current design.

Do not add a NAT Gateway, VPC endpoint, or broad egress rule merely to make a failed connection work. First identify the exact connectivity requirement and evaluate the security and cost implications.

AWS Systems Manager Session Manager is not currently configured for this project.

## 4. Escalation and Recovery

If the issue remains unresolved:

1. Record the exact SSH error and the connection path that failed.
2. Record the affected instance ID, AWS account, region, and relevant security-group IDs.
3. Collect relevant read-only configuration and status-check results.
4. Identify the suspected root cause before proposing changes.
5. Obtain approval before modifying network controls or instance configuration.
6. Review and validate any Terraform change and its plan before applying it.

Do not disable termination protection, widen SSH ingress, or modify unrelated shared-account resources as an exploratory troubleshooting step.

## 5. Related Documentation

- [Architecture Overview](../ARCHITECTURE.md)
- [Security Design](../SECURITY.md)
- [Terraform Deployment Runbook](terraform-deployment.md)
- [Terraform Destruction Runbook](terraform-destruction.md)
- [ADR-0002: Bastion-Based SSH Access](../adr/0002-bastion-ssh-access.md)
- [ADR-0003: Private Instance Isolation](../adr/0003-private-instance-isolation.md)