locals {
  tags = {
    Blueprint = var.cluster_name
  }
}

variable "role_arn" {
  description = "The ARN of the role to grant cluster admin access (used by tfstacks-role)"
  type        = string
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.2.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.kubernetes_version
  cluster_endpoint_public_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  enable_irsa = true

  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  cluster_enabled_log_types = [] #disabling logs for cost - lab only

  fargate_profiles = {
    app_wildcard = {
      selectors = [
        { namespace = "hashibank*" },
        { namespace = "product*" },
        { namespace = "consul*" },
        { namespace = "frontend*" },
        { namespace = "payments*" }
      ]
    }
    kube_system = {
      name = "kube-system"
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

  fargate_profile_defaults = {
    timeouts = {
      create = "30m"
      update = "30m"
      delete = "30m"
    }
  }


  enable_cluster_creator_admin_permissions = false

  access_entries = {
    # One access entry with a policy associated
    single = {
      kubernetes_groups = []
      principal_arn     = var.eks_clusteradmin_arn
      username          = var.eks_clusteradmin_username

      policy_associations = {
        single = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    },
    # This grants the HCP Terraform OIDC role full cluster admin access
    tfc_oidc_role = {
      principal_arn  = var.role_arn

      # cannot use system:* groups here (API rejects them); leave empty and rely on the policy association
      kubernetes_groups = []

      policy_associations = {
        cluster_admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = local.tags
}

data "aws_eks_cluster" "upstream" {
  depends_on = [module.eks]
  name       = var.cluster_name
}

data "aws_eks_cluster_auth" "upstream_auth" {
  depends_on = [module.eks]
  name       = var.cluster_name
}

resource "aws_eks_identity_provider_config" "oidc_config" {
  depends_on = [module.eks]
  cluster_name = var.cluster_name

  oidc {
    identity_provider_config_name = "tfstack-terraform-cloud"
    client_id                     = var.tfc_kubernetes_audience
    issuer_url                    = var.tfc_hostname
    username_claim                = "sub"
    groups_claim                  = "terraform_organization_name"
  }
}

