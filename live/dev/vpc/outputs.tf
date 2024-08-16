output "private_subnet_ids" {
  description = "VPC Private subnets ids"
  value       = module.vpc.private_subnet_ids
}
