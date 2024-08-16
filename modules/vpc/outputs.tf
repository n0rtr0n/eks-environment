output "azs" {
  description = "Availability zones of VPC"
  value       = module.vpc.azs
}

output "private_subnet_ids" {
  description = "VPC Public subnet ids"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "VPC Private subnet ids"
  value       = module.vpc.public_subnets
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}
