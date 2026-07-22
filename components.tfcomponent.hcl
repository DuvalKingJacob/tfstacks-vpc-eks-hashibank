# This file defines the platform components and their dependency graph.

# AWS VPC
component "vpc" {
  for_each = var.regions
  source   = "./aws-vpc"

  inputs = {
    vpc_name = var.vpc_name
    vpc_cidr = var.vpc_cidr
  }

  providers = {
    aws = provider.aws.configurations[each.value]
  }
}

# AWS EKS
component "eks" {
  for_each = var.regions
  source   = "./aws-eks-fargate"

  inputs = {
    vpc_id                    = component.vpc[each.value].vpc_id
    private_subnets           = component.vpc[each.value].private_subnets
    kubernetes_version        = var.kubernetes_version
    cluster_name              = var.cluster_name
    tfc_hostname              = var.tfc_hostname
    tfc_kubernetes_audience   = var.tfc_kubernetes_audience
    eks_clusteradmin_arn      = var.eks_clusteradmin_arn
    eks_clusteradmin_username = var.eks_clusteradmin_username
    role_arn                  = var.role_arn
    enable_irsa               = var.enable_irsa
  }

  providers = {
    aws        = provider.aws.configurations[each.value]
    cloudinit  = provider.cloudinit.this
    kubernetes = provider.kubernetes.this
    time       = provider.time.this
    tls        = provider.tls.this
  }
}

# Kubernetes RBAC for the HCP Terraform workload identity.
component "k8s-rbac" {
  for_each = var.regions
  source   = "./k8s-rbac"

  inputs = {
    cluster_endpoint                   = component.eks[each.value].cluster_endpoint
    cluster_certificate_authority_data = component.eks[each.value].cluster_certificate_authority_data
    eks_token                          = component.eks[each.value].eks_token
    tfc_organization_name              = var.tfc_organization_name
  }

  providers = {
    kubernetes = provider.kubernetes.configurations[each.value]
  }

  depends_on = [component.eks]
}

# EKS add-ons: AWS Load Balancer Controller, CoreDNS, VPC CNI, and kube-proxy.
component "k8s-addons" {
  for_each = var.regions
  source   = "./aws-eks-addon"

  inputs = {
    cluster_name                       = component.eks[each.value].cluster_name
    vpc_id                             = component.vpc[each.value].vpc_id
    cluster_endpoint                   = component.eks[each.value].cluster_endpoint
    cluster_version                    = component.eks[each.value].cluster_version
    cluster_certificate_authority_data = component.eks[each.value].cluster_certificate_authority_data
    oidc_provider_arn                  = component.eks[each.value].oidc_provider_arn
    oidc_binding_id                    = component.k8s-rbac[each.value].oidc_binding_id
  }

  providers = {
    kubernetes = provider.kubernetes.configurations[each.value]
    helm       = provider.helm.configurations[each.value]
    aws        = provider.aws.configurations[each.value]
    time       = provider.time.this
  }

  # The RBAC binding must exist before CRD and Helm operations begin.
  depends_on = [component.k8s-rbac]
}

# HashiBank namespace.
component "k8s-namespace" {
  for_each = var.regions
  source   = "./k8s-namespace"

  inputs = {
    namespace = var.namespace
    labels    = component.k8s-addons[each.value].eks_addons
  }

  providers = {
    kubernetes = provider.kubernetes.configurations[each.value]
  }

  depends_on = [component.k8s-rbac]
}

# HashiBank application.
component "deploy-hashibank" {
  for_each = var.regions
  source   = "./hashibank-deploy"

  inputs = {
    hashibank_namespace = component.k8s-namespace[each.value].namespace
  }

  providers = {
    kubernetes = provider.kubernetes.configurations[each.value]
    time       = provider.time.this
  }

  depends_on = [component.k8s-rbac, component.k8s-namespace]
}
