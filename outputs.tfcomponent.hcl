output "published_vpc_id" {
  type        = string
  description = "The VPC ID published by the development deployment for downstream Stacks."
  value       = component.vpc[one(var.regions)].vpc_id
}
