output "private_subnet_ids" {
  description = "VPC Private subnets ids"
  value       = module.vpc.private_subnet_ids
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}
