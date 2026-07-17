# Terraform Stacks: VPC, EKS, and HashiBank

This repository demonstrates a platform-shaped Terraform Stack that coordinates:

```text
VPC -> EKS Fargate -> Kubernetes RBAC -> EKS add-ons -> namespace -> HashiBank
```

The component configuration defines what the platform contains. The deployment configuration defines how the same platform is deployed to development and production with different approval behavior.

## Stack Files

- `components.tfcomponent.hcl`: component graph and cross-component inputs
- `deployments.tfdeploy.hcl`: deployments, workload identity, approval rules, and published outputs
- `providers.tfcomponent.hcl`: provider requirements and configurations
- `variables.tfcomponent.hcl`: Stack input contract and validation
- `outputs.tfcomponent.hcl`: outputs available to deployments

## Prerequisites

- Terraform with the `terraform stacks` commands
- an HCP Terraform project and Stack connected to this repository
- AWS workload identity configured for Terraform Stacks
- Kubernetes and Helm access established by the EKS deployment
- an HCP Terraform variable set named `hashibank-stack-runtime`

For the AWS OIDC prerequisite, see [AWS OpenID role for Stacks](https://github.com/hashi-demo-lab/aws-openid-role-for-stacks).

## Runtime Variable Set

Create `hashibank-stack-runtime` as a Terraform-category variable set and assign it to the Stack or its project. It keeps environment-specific identifiers out of the active deployment configuration:

- `tfc_organization_name`
- `dev_role_arn`
- `dev_cluster_admin_arn`
- `dev_cluster_admin_username`
- `prod_role_arn`
- `prod_cluster_admin_arn`
- `prod_cluster_admin_username`

These identifiers are referenced with `store.varset.runtime.stable` because the infrastructure resources and provider configuration require consistent values across deployment runs. OIDC identity tokens remain ephemeral.

The demo currently targets EKS 1.34, which remains in standard support during the recording window. Managed EKS add-ons use the most recent version compatible with the selected cluster version.

## Approval Model

- Development automatically approves plans that remove no resources.
- Production has no auto-approval rule and therefore requires human approval.
- Neither deployment is marked for destruction in the repository.

## Validate

```bash
terraform stacks fmt
terraform stacks init
terraform stacks validate
```

## Recording Safety

Before a public demo, confirm that the variable set is attached, both target accounts are disposable demo environments, and the pending configuration contains no destroy operation. Do not show state, role values, account IDs, kubeconfigs, or variable-set contents on screen.
