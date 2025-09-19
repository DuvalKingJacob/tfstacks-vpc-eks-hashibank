output "vpc_id" {
  type = string
  description = "The ID of the VPC from the us-east-1 deployment, exposed for Linked Stacks."
  value       = component.vpc["us-east-1"].vpc_id
}