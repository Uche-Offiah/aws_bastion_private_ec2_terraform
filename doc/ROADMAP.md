# Terraform Bastion and Private EC2 — Iteration Roadmap

- **Status:** Proposed roadmap
- **Last updated:** 2026-10-30
- **Repository:** `urch/aws_bastion_private_ec2_terraform`
- **Primary branch:** `main`
- **AWS region:** `us-east-2`

## 1. Purpose

This roadmap defines the remaining project iterations, their scope, acceptance criteria, branching policy, and release requirements.

The project will progress from a secure, locally runnable Terraform implementation to a modular, team-ready infrastructure configuration with remote Terraform state.

Local execution must remain supported where practical. Remote state will be introduced deliberately in Iteration 7 rather than being a prerequisite for the local-ready release in Iteration 5.

**No infrastructure deployment is authorized by this roadmap.** A reviewed Terraform plan is not permission to run `terraform apply`.

## 2. Iteration overview

| Iteration | Scope | Target release |
|---|---|---|
| 3 | CI, security scanning, and infrastructure security improvements | `v3.0.0` |
| 4 | Documentation and audit completion | No standalone release required |
| 5 | Local-ready verification and release | `v5.0.0` |
| 6 | Configuration and modular architecture review | `v6.0.0` |
| 7 | Terraform state strategy, remote backend implementation, and final release | `v7.0.0` |

Each iteration will have its own feature branch and documented scope. Iterations will be merged into `main` only after their acceptance criteria pass.

The release tags above are targets, not permission to create tags before the corresponding release is accepted.

## 3. Iteration 3 — CI and infrastructure security

**Feature branch:** `feature/iteration-3-enterprise-iac`

**Target tag:** `v3.0.0`

### Scope

1. Implement automated Terraform formatting and validation checks for pull requests and relevant pushes.
2. Integrate infrastructure-as-code security scanning.
3. Review security findings and implement appropriate remediations.
4. Document intentional exceptions, residual risks, and conditions that require reassessment.

The broader configuration/module review is moved to Iteration 6. Terraform state strategy and remote backend implementation are moved to Iteration 7.

### Acceptance criteria

- [ ] CI runs Terraform formatting and validation.
- [ ] Security scanning runs automatically and produces reviewable results.
- [ ] Findings are remediated or have documented, justified exceptions.
- [ ] Intentional exceptions identify their rationale and when reassessment is required.
- [ ] Terraform configuration passes formatting and validation.
- [ ] Documentation accurately reflects implemented security controls and limitations.
- [ ] All changes are committed atomically by logical change and pushed to the feature branch.
- [ ] The final review and applicable CI checks pass before merging.
- [ ] The accepted branch is merged into `main` and tagged `v3.0.0`.

### Release restrictions

Do not apply infrastructure as part of the release process unless separately requested and explicitly approved.

## 4. Iteration 4 — Documentation and audit completion

**Feature branch:** `feature/iteration-4-documentation-audit`

### Scope

Complete the documentation and audit evidence needed for a maintainable, reviewable Terraform project.

Review and reconcile:

- `README.md`
- `doc/ARCHITECTURE.md`
- `doc/SECURITY.md`
- `doc/adr/`
- `doc/runbooks/terraform-deployment.md`
- `doc/runbooks/terraform-destruction.md`
- `doc/runbooks/bastion-access-troubleshooting.md`

### Acceptance criteria

- [ ] Architecture documentation matches the actual Terraform resources and traffic flows.
- [ ] Security documentation describes implemented controls, limitations, and accepted risks.
- [ ] ADRs follow the existing project template and record accepted decisions accurately.
- [ ] Deployment and destruction runbooks provide safe, ordered procedures with explicit review and approval gates.
- [ ] The documentation distinguishes current implementation from deferred or proposed functionality.
- [ ] No documentation claims that infrastructure was deployed or tested when that has not occurred.
- [ ] Cross-references, filenames, resource names, and commands are verified.
- [ ] Documentation changes are reviewed and committed in logical units.
- [ ] The Iteration 4 completion review passes before Iteration 5 begins.

Iteration 4 does not need a standalone version tag unless a separately useful release is justified.

## 5. Iteration 5 — Local-ready verification and release

**Feature branch:** `feature/iteration-5-local-ready-release`

**Target tag:** `v5.0.0`

### Objective

Deliver a stable version that an individual developer can clone and use without provisioning a remote Terraform backend.

### Scope

- Complete end-to-end local workflow verification.
- Verify Terraform initialization, formatting, validation, and planning.
- Complete the final security and documentation review.
- Confirm that the repository does not require an S3 backend to initialize and inspect a plan.
- Establish a reproducible release from `main`.

### Acceptance criteria

- [ ] A clean checkout of the release candidate can be initialized locally.
- [ ] Terraform formatting and validation pass.
- [ ] CI and infrastructure security scanning pass their defined acceptance requirements.
- [ ] Required configuration inputs and the example variable file are documented.
- [ ] State files, sensitive variable files, and saved plan files are excluded from Git as intended.
- [ ] The local deployment runbook accurately describes initialization, planning, and safe review.
- [ ] A Terraform plan is generated and inspected for unexpected changes.
- [ ] No infrastructure is applied as part of acceptance testing.
- [ ] All changes are reviewed and committed.
- [ ] The accepted changes are merged into `main`.
- [ ] Tag `v5.0.0` points to the accepted release commit.
- [ ] The tag and its release notes identify this as the local-ready release.

### Compatibility guarantee

A user checking out `v5.0.0` must not need a pre-existing S3 state bucket, remote backend permissions, or a backend migration to initialize and plan the project.

This release is a stable milestone, not the end of the project.

## 6. Iteration 6 — Configuration and modular architecture

**Feature branch:** `feature/iteration-6-modular-environment-architecture`

**Target tag:** `v6.0.0`

### Objective

### Objective

Implement the configuration structure, reusable module boundaries, and environment separation required to move the project toward its target enterprise-ready architecture while preserving a practical local workflow.

### Scope

- Assess whether reusable Terraform modules are justified by the current architecture.
- Review root-module responsibilities and input/output boundaries.
- Evaluate how development and future environments should be separated.
- Consider state isolation and environment-specific configuration.
- Preserve local execution compatibility.
- Update architecture documentation and ADRs to reflect accepted decisions.

### Acceptance criteria

- [ ] A documented architecture review defines the target configuration, module boundaries, and environment separation.
- [ ] The agreed module architecture is implemented and verified; any deferred component has a documented rationale and acceptance decision.
- [ ] If modules are introduced, their inputs, outputs, responsibilities, and dependencies are documented.
- [ ] Environment separation is explicit and does not rely on assumptions about the active environment.
- [ ] Development and future environments cannot accidentally share state unintentionally.
- [ ] No environment or module change silently introduces a remote backend dependency.
- [ ] The local workflow from Iteration 5 remains supported and is revalidated.
- [ ] Formatting, initialization, validation, CI, and security scanning pass.
- [ ] Documentation and ADRs reflect the final architecture.
- [ ] A reviewed Terraform plan shows no unexpected changes.
- [ ] Changes are merged into `main` only after acceptance.
- [ ] Tag `v6.0.0` identifies the accepted release.


## 7. Iteration 7 — Terraform state strategy and final release

**Feature branch:** `feature/iteration-7-remote-state-final-release`

**Target tag:** `v7.0.0`

### Objective

Implement a secure and recoverable remote-state workflow for shared use while retaining local execution where practical.

### Scope

- Finalize the Terraform state strategy ADR.
- Design and implement the S3 backend workflow.
- Establish a separate bootstrap process for backend infrastructure.
- Configure and document state locking, encryption, access control, and recovery.
- Define safe state migration and operational procedures.
- Revalidate the local workflow.
- Complete final project documentation and release verification.

### Acceptance criteria

#### State architecture

- [ ] The ADR distinguishes local state from remote state and explains the trade-offs.
- [ ] The selected backend and its operational prerequisites are documented.
- [ ] The backend bootstrap process is separate from the infrastructure that consumes the backend.
- [ ] The state design addresses concurrency, encryption, least-privilege access, and recovery.
- [ ] The S3 design includes versioning, public-access blocking, and appropriate transport security.
- [ ] Terraform's supported native S3 lockfile mechanism is evaluated and configured if the S3 backend is selected.
- [ ] State and saved plan files remain excluded from version control.
- [ ] No secrets or sensitive state contents are added to source control or logs.

#### Bootstrap and migration

- [ ] Backend provisioning instructions are reproducible and reviewed.
- [ ] The procedure verifies that the intended bucket and key are used.
- [ ] State migration, if required, includes a verified backup and a reviewed migration procedure.
- [ ] Recovery instructions explain how to restore a prior state version safely.
- [ ] The procedure requires a subsequent plan review after restoration or migration.
- [ ] No existing state is deleted or overwritten without explicit approval.

#### Compatibility and testing

- [ ] The remote-state workflow is verified using the documented bootstrap prerequisites.
- [ ] The local workflow remains available and is tested independently.
- [ ] Backend-specific configuration does not force local users to provision remote infrastructure.
- [ ] Formatting, initialization, validation, CI, security scanning, and documentation checks pass.
- [ ] The final Terraform plan is reviewed and contains no unexpected changes.
- [ ] No infrastructure deployment is performed without separate explicit approval.

#### Final release

- [ ] All Iteration 7 changes are reviewed and committed.
- [ ] All required acceptance criteria are satisfied.
- [ ] Changes are merged into `main`.
- [ ] Tag `v7.0.0` points to the accepted final release commit.
- [ ] Release notes describe supported workflows, backend prerequisites, migration considerations, and known limitations.
- [ ] Documentation identifies `v7.0.0` as the final planned project milestone.

## 8. Branch and commit policy

1. Create one feature branch per iteration, with its scope and acceptance criteria documented.
2. Keep changes on the branch limited to the iteration's agreed scope.
3. Use multiple atomic commits for logically distinct changes.
4. Run relevant formatting, validation, tests, security scanning, and plan review before requesting a merge.
5. Review the complete diff and the final Git status before committing or merging.
6. Merge accepted work into `main`.
7. Create release tags only after acceptance criteria pass.
8. Never move or reuse an existing release tag to point at different code.
9. Preserve prior releases as reproducible reference points.
10. Do not treat a successful plan as approval to apply infrastructure.

## 9. Release verification checklist

Before any release tag is created:

- [ ] Confirm the feature branch and target release scope.
- [ ] Confirm that the working tree is clean.
- [ ] Confirm the expected commits and review the final diff.
- [ ] Run `terraform fmt -check -recursive`.
- [ ] Initialize Terraform using the workflow appropriate to the release.
- [ ] Run `terraform validate`.
- [ ] Confirm CI and security scanning results.
- [ ] Review the documentation and ADRs.
- [ ] Generate and inspect a Terraform plan where the required configuration and credentials are available.
- [ ] Investigate unexpected changes rather than bypassing them.
- [ ] Confirm that no apply or destructive action is implied by the release process.
- [ ] Merge the accepted branch into `main`.
- [ ] Create the release tag on the accepted commit.
- [ ] Verify the tag and record release notes.

If a check cannot be run, document the reason and obtain an explicit acceptance decision rather than silently treating the check as passed.

## 10. Change control

This roadmap is the planning baseline for Iterations 3–7. Changes to scope, acceptance criteria, or release numbering must be documented and reviewed before implementation.

Existing release tags remain immutable. The new roadmap does not retroactively change the contents or meaning of any previously created tag.

Any deployment, state migration, resource destruction, or other consequential AWS operation requires separate review and explicit approval.
