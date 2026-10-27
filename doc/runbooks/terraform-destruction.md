# Runbook: Terraform Destruction

## 1. Purpose

This runbook describes how to review and execute Terraform destruction for the AWS Bastion and Private EC2 project.

Destroying infrastructure is a potentially destructive operation. The AWS account is shared with other projects, so scope and impact must be confirmed before any destructive action.

**Do not run `terraform destroy` without explicit approval.**

## 2. Preconditions

Before considering destruction:

- Confirm the AWS account, region, and Terraform workspace.
- Confirm that the Terraform state belongs to this project and does not manage unrelated resources.
- Review dependencies and identify any data or resources that must be retained.
- Confirm that destroying the infrastructure is intentional and approved.
- Ensure that required backups or other recovery measures exist.

## 3. Review the Planned Destruction

Generate a destroy plan:

```bash
terraform plan -destroy -out=tfplan-destroy
```

Inspect it:

```bash
terraform show -no-color tfplan-destroy
```

Verify that every resource proposed for destruction belongs to the intended project and that no unrelated resources will be affected.

If the plan includes unexpected resources, stop. Do not proceed until the scope has been understood and corrected.

## 4. EC2 Termination Protection

The EC2 instances in this project have API termination protection enabled.

Termination protection may prevent an instance from being terminated through the normal EC2 termination API until protection is disabled. Terraform destruction can therefore fail if this setting remains enabled.

Do not disable termination protection automatically as part of an unreviewed cleanup.

If destruction is approved:

1. Identify the exact instance or instances requiring termination.
2. Confirm that the termination is intended and that required data is retained.
3. Obtain approval to disable termination protection.
4. Disable protection using the appropriate reviewed Terraform change or approved AWS operation.
5. Review and approve the resulting Terraform plan before proceeding.

Where possible, make protection changes through Terraform so that configuration and deployed state remain aligned.

## 5. Execute Destruction

After the destroy plan has been reviewed and explicit approval obtained, execute the reviewed saved plan:

```bash
terraform apply tfplan-destroy
```

If the plan is stale or Terraform reports a state or dependency error, stop and investigate. Do not bypass the failure by issuing an unreviewed destroy command.

## 6. Verify the Result

After approved destruction, verify the intended resources have been removed.

```bash
terraform state list
```

An empty state list indicates that no resources remain in the current Terraform state, but it does not prove that all AWS resources associated with the project have been removed.

Check the AWS console or appropriate AWS CLI commands for residual resources and review any costs or data-retention obligations.

## 7. Important Considerations

- Do not manually delete resources without understanding the effect on Terraform state.
- Do not delete Terraform state as a way to clean up resources.
- Do not assume that deleting an EC2 instance removes every related resource.
- Root EBS volumes are configured for deletion on instance termination, but independently managed volumes, snapshots, or other resources may have different retention behavior.
- Preserve required data and evidence before destruction.
- Record the outcome of the cleanup and any resources intentionally retained.