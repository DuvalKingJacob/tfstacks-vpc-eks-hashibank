output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "cluster_name" {
  description = "eks cluster_name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = data.aws_eks_cluster.upstream.endpoint
}

output "cluster_version" {
  description = "eks cluster_version"
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "eks idc_provider_arn"
  value       = module.eks.oidc_provider_arn
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster CA data"
  value       = data.aws_eks_cluster.upstream.certificate_authority[0].data
}

output "eks_token" {
  description = "EKS token (short‑lived) used to authenticate as cluster creator"
  value       = data.aws_eks_cluster_auth.upstream_auth.token
  sensitive   = true
}