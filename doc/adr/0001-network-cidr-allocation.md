# ADR-0001: VPC CIDR Allocation

- **Status:** Accepted
- **Date:** 2026-10-26

## Context

The project requires a dedicated VPC for the AWS Bastion and Private EC2 proof of concept (POC).

The CIDR allocation must avoid overlapping with existing VPC networks and provide sufficient address space to accommodate future growth as the architecture evolves.

Existing VPC CIDRs in the AWS environment include:

- `10.0.0.0/16`
- `172.31.0.0/16`

## Decision

Allocate `10.20.0.0/16` to the project VPC.

Allocate the following `/24` subnets for the initial architecture:

- **Public subnet:** `10.20.1.0/24`
- **Private subnet:** `10.20.2.0/24`

The remaining VPC address space is available for future subnet allocations as project requirements evolve.

## Alternatives considered

- **Use an existing VPC:** Rejected because the project requires its own network boundary and should not introduce unnecessary dependencies on existing infrastructure.
- **Use an overlapping CIDR:** Rejected because overlapping address ranges can complicate or prevent routing between connected networks.
- **Use a smaller VPC CIDR:** Not selected because the POC is intended to explore future network architecture and scaling considerations, making additional address space useful.

## Consequences

### Benefits

- Avoids overlap with the identified existing VPC CIDRs.
- Provides room for additional subnets and future architectural changes.
- Establishes a dedicated network boundary for the project.

### Trade-offs

- The `/16` address space is larger than the current two `/24` subnets require.
- A larger CIDR does not itself provide scalability or security; subnet design, routing, and infrastructure configuration must evolve with future requirements.

## Implementation

- `main.tf` — VPC and subnet resources.
- `variable.tf` — configurable VPC and subnet CIDRs.
- `doc/ARCHITECTURE.md` — network architecture documentation.

## References

- [RFC 1918: Address Allocation for Private Internets](https://www.rfc-editor.org/rfc/rfc1918)
- `doc/SECURITY.md` — network access controls and security assumptions.