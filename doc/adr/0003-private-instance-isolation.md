# ADR-0003: Private Instance Isolation

- **Status:** Accepted
- **Date:** 2026-10-26

## Context

The project deploys a private EC2 instance as part of a proof of concept intended to demonstrate secure network architecture and provide a foundation for future improvements.

The private instance should not be directly accessible from the public internet. Its network placement and access controls should reduce the attack surface and support defense in depth and least privilege.

The initial workload does not have a confirmed requirement for general outbound internet access or direct connectivity to other AWS services.

## Decision

Deploy the private EC2 instance in a private subnet with the following controls:

- Do not assign a public IP address to the instance.
- Do not configure an internet default route in the private subnet's route table.
- Do not configure security-group ingress except for the required SSH access from the bastion security group.
- Do not configure security-group egress rules until a specific connectivity requirement justifies them.

Defer NAT Gateway and VPC endpoint implementation until the project's workload and management requirements are better understood.

Any future connectivity additions must be reviewed for their security implications, routing requirements, operational complexity, and cost.

## Alternatives considered

### Place the instance in a public subnet

Not selected. A public-facing instance would increase exposure and would not meet the intended private-infrastructure isolation objective.

### Add a NAT Gateway

Deferred. A NAT Gateway could provide outbound internet connectivity for resources in private subnets without assigning those resources public IP addresses. However, it introduces additional infrastructure and ongoing cost that is not justified by a confirmed requirement in the current POC.

### Add VPC endpoints

Deferred. VPC endpoints may allow private access to supported AWS services without requiring general internet connectivity. The appropriate endpoint types and policies depend on which AWS services the workload will use. No specific endpoint requirement has been established yet.

### Allow unrestricted security-group egress

Not selected. Broad egress would permit more outbound traffic than the current design requires and would weaken the principle of least privilege.

## Consequences

### Benefits

- Prevents direct public-IP-based access to the private instance.
- Avoids a default route from the private subnet to the internet.
- Limits explicitly permitted network traffic.
- Avoids premature infrastructure cost and complexity.
- Leaves room to introduce controlled connectivity as the architecture evolves.

### Trade-offs and limitations

- The private instance cannot use the current network design for general internet access.
- Package installation, software updates, and access to AWS services may require additional connectivity or a different management approach.
- Security-group rules alone do not determine reachability; routing, network ACLs, and other applicable controls also matter.
- Future connectivity requirements must be evaluated individually rather than solved by automatically adding broad egress access.

## Implementation

- `main.tf` — VPC, subnet, route table, and security-group resources.
- `compute.tf` — private EC2 instance configuration.
- `doc/SECURITY.md` — isolation controls and known limitations.
- `doc/ARCHITECTURE.md` — network boundaries and traffic flows.

## References

- ADR-0001: VPC CIDR Allocation.
- ADR-0002: Bastion-Based SSH Access.
- `doc/SECURITY.md` — security controls and known limitations.