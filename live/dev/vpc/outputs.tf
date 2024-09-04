output "private_subnet_ids" {
  description = "VPC private subnets ids"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "VPC public subnets ids"
  value       = module.vpc.public_subnet_ids
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR range"
  value       = module.vpc.vpc_cidr_block
}
