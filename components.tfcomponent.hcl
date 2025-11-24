# This file defines the "what" - the building blocks of our stack.

#AWS VPC
component "vpc" {
  for_each = var.regions

  source = "./aws-vpc"

  inputs = {
    vpc_name = var.vpc_name
    vpc_cidr = var.vpc_cidr
  }

  providers = {
    aws     = provider.aws.configurations[each.value]
  }
} 

#AWS EKS
component "eks" {
  for_each = var.regions

  source = "./aws-eks-fargate"

  inputs = {
    vpc_id = component.vpc[each.value].vpc_id
    private_subnets = component.vpc[each.value].private_subnets
    kubernetes_version = var.kubernetes_version
    cluster_name = var.cluster_name
    tfc_hostname = var.tfc_hostname
    tfc_kubernetes_audience = var.tfc_kubernetes_audience
    eks_clusteradmin_arn = var.eks_clusteradmin_arn
    eks_clusteradmin_username = var.eks_clusteradmin_username
    role_arn = var.role_arn

  }

  providers = {
    aws    = provider.aws.configurations[each.value]
    cloudinit = provider.cloudinit.this
    kubernetes  = provider.kubernetes.this
    time = provider.time.this
    tls = provider.tls.this
  }
}

# Update K8s role-binding
component "k8s-rbac" {
  for_each = var.regions

  source = "./k8s-rbac"

  inputs = {
    # pass the EKS outputs the k8s-rbac module expects
    cluster_endpoint       = component.eks[each.value].cluster_endpoint
    cluster_ca_certificate = component.eks[each.value].cluster_certificate_authority_data
    eks_token              = component.eks[each.value].eks_token
    tfc_organization_name  = var.tfc_organization_name
  }

  # Use the provider configuration that authenticates with the EKS token (not the TFC OIDC provider)
  providers = {
    kubernetes = provider.kubernetes.configurations[each.value]
  }

  # ensure EKS outputs (aws-eks-fargate) are created before we manage cluster-scoped RBAC
  depends_on = [component.eks]
}

# K8s Addons - aws load balancer controller, coredns, vpc-cni, kube-proxy
component "k8s-addons" {
  for_each = var.regions

  source = "./aws-eks-addon"

  inputs = {
    cluster_name                         = component.eks[each.value].cluster_name
    vpc_id                               = component.vpc[each.value].vpc_id
    private_subnets                       = component.vpc[each.value].private_subnets
    cluster_endpoint                     = component.eks[each.value].cluster_endpoint
    cluster_version                      = component.eks[each.value].cluster_version
    cluster_certificate_authority_data   = component.eks[each.value].cluster_certificate_authority_data
    oidc_provider_arn                    = component.eks[each.value].oidc_provider_arn
    oidc_binding_id                      = component.k8s-rbac[each.value].oidc_binding_id
  }

  providers = {
    kubernetes  = provider.kubernetes.configurations[each.value]
    helm        = provider.helm.configurations[each.value]
    aws         = provider.aws.configurations[each.value]
    time        = provider.time.this
  }

  # ensure the RBAC binding is created first so CRD/helm installs run with cluster-admin privileges
  depends_on = [component.k8s-rbac]
}

# Namespace
component "k8s-namespace" {
  for_each = var.regions

  source = "./k8s-namespace"

  inputs = {
    namespace = var.namespace
    labels = component.k8s-addons[each.value].eks_addons
  }

  providers = {
    kubernetes  = provider.kubernetes.oidc_configurations[each.value]
  }
}

# Deploy Hashibank
component "deploy-hashibank" {
  for_each = var.regions

  source = "./hashibank-deploy"

  inputs = {
    hashibank_namespace = component.k8s-namespace[each.value].namespace
  }

  providers = {
    kubernetes  = provider.kubernetes.oidc_configurations[each.value]
    time = provider.time.this
  }
}

# This is the new, critical block. It formally exposes the VPC ID
# from the 'vpc' component as a top-level Stack output.
# Still commented out for now.
output "published_vpc_id" {
  description = "The ID of the VPC from the development deployment."
  type        = string
  value       = component.vpc["us-east-1"].vpc_id
}

