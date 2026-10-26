# ADR-0002: Bastion-Based SSH Access

- **Status:** Accepted
- **Date:** 2026-10-26

## Context

The project requires administrative SSH access to an EC2 instance deployed in a private subnet.

The architecture may eventually host sensitive infrastructure, such as databases and private application workloads. Exposing these resources directly to external networks would increase the attack surface and weaken network isolation.

The design should follow the principles of defense in depth and least privilege by controlling how administrators reach private infrastructure.

## Decision

Use a public bastion EC2 instance as the designated SSH entry point to the private EC2 instance.

Implement the following access controls:

- Restrict inbound SSH on the bastion to the administrator CIDR configured through `admin_cidr`.
- Permit inbound SSH on the private instance only from the bastion security group.
- Do not assign a public IP address to the private instance.
- Permit bastion-to-private-instance SSH egress on TCP port 22.

Administrators must connect to the bastion before establishing an SSH session to the private instance.

## Alternatives considered

### Direct SSH access to the private instance

Not selected. The private instance should not require direct external SSH exposure. Access through a designated entry point better supports network isolation and controlled administrative access.

### AWS Systems Manager Session Manager

Not selected for the initial implementation. Session Manager is a potential alternative that could remove the need for inbound SSH access, but it requires appropriate IAM permissions and a working management connectivity path. It has not been implemented or tested in this project.

## Consequences

### Benefits

- Reduces direct network exposure of private infrastructure.
- Creates a designated administrative entry point.
- Supports defense in depth by separating external access from private workload access.
- Limits SSH ingress to explicitly authorized sources.
- Provides a foundation for extending the architecture to additional private workloads.

### Trade-offs and risks

- The bastion becomes a security-sensitive entry point and must be appropriately hardened, monitored, and maintained.
- Administrative access depends on the bastion being available and reachable.
- SSH keys and administrator access must be managed securely.
- A compromised bastion could increase the risk to private resources reachable from it.
- Session Manager may offer a suitable alternative as the project's management and auditing requirements evolve.

## Implementation

- `main.tf` — security groups and SSH ingress/egress rules.
- `compute.tf` — bastion and private EC2 instances.
- `variable.tf` — administrator CIDR configuration and validation.
- `doc/SECURITY.md` — network access controls and security assumptions.
- `doc/ARCHITECTURE.md` — network architecture and traffic flow.

## References

- ADR-0001: VPC CIDR Allocation.
- `doc/SECURITY.md` — security controls and known limitations.