# This file defines the "execution plan" for the Stack, following the correct GA syntax.
# NOTE: Your local editor may show syntax errors, but this is the correct structure for the HCP Terraform GA runner.

# ----------------------------------------------------
# Step 1: Define Identity Tokens
# ----------------------------------------------------
identity_token "aws" {
  audience = ["aws.workload.identity"]
}

identity_token "k8s" {
  audience = ["k8s.workload.identity"]
}
publish_output "vpc_id" {
  value = deployment.development.published_vpc_id
}

# ----------------------------------------------------
# Step 2: Define Auto-Approval Rules
# ----------------------------------------------------
deployment_auto_approve "safe_dev_plans" {
  check {
    # This rule only passes if no resources are being deleted.
    condition     = context.plan.changes.remove == 0
    reason        = "Plan has ${context.plan.changes.remove} resources to be removed. Manual approval required."
  }
}

# ----------------------------------------------------
# Step 3: Define Deployment Groups and Assign Rules
# ----------------------------------------------------
deployment_group "dev_group" {
  # The dev group uses the auto-approval rule.
  auto_approve_checks = [
    deployment_auto_approve.safe_dev_plans
  ]
}

deployment_group "prod_group" {
  # The prod group has no rules, so it will always require manual approval.
  auto_approve_checks = []
}

# ----------------------------------------------------
# Step 4: Define Deployments and Assign Them to Groups
# ----------------------------------------------------
deployment "development" {
  # Assign this deployment to the 'dev_group'.
  deployment_group = deployment_group.dev_group
  destroy=true
  inputs = {
    aws_identity_token        = identity_token.aws.jwt
    role_arn                  = "arn:aws:iam::177099687113:role/tfstacks-role"
    regions                   = ["us-east-1"]
    vpc_name                  = "aeyuthira-dev"
    vpc_cidr                  = "10.0.0.0/16"
    kubernetes_version        = "1.30"
    cluster_name              = "hideyaki-dev-final"
    tfc_kubernetes_audience   = "k8s.workload.identity"
    tfc_hostname              = "https://app.terraform.io"
    tfc_organization_name     = "vearadyn"
    eks_clusteradmin_arn      = "arn:aws:iam::177099687113:role/aws_jacob.plicque_test-developer"
    eks_clusteradmin_username = "aws_jacob.plicque_test-developer"
    k8s_identity_token        = identity_token.k8s.jwt
    namespace                 = "hashibank"
  }
}

deployment "prod" {
  # Assign this deployment to the 'prod_group'.
  deployment_group = deployment_group.prod_group
  inputs = {
    aws_identity_token        = identity_token.aws.jwt
    role_arn                  = "arn:aws:iam::177099687113:role/tfstacks-role"
    regions                   = ["us-east-1"]
    vpc_name                  = "aeyuthirai-prod"
    vpc_cidr                  = "10.20.0.0/16"
    kubernetes_version        = "1.30"
    cluster_name              = "hideyaki-eksprod01-final"
    tfc_kubernetes_audience   = "k8s.workload.identity"
    tfc_hostname              = "https://app.terraform.io"
    tfc_organization_name     = "vearadyn"
    eks_clusteradmin_arn      = "arn:aws:iam::855831148133:role/aws_jacob.plicque_test-developer"
    eks_clusteradmin_username = "aws_jacob.plicque_test-developer"
    k8s_identity_token        = identity_token.k8s.jwt
    namespace                 = "hashibank"
  }
}
