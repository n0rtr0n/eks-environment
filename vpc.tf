data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  env = "dev"
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "eks-testing"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.12.1"

  name = "${local.vpc_name}-${local.env}"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  # Internet Gateway for public subnets
  create_igw = true

  # DNS
  enable_dns_support = true

  # since we have private subnets 
  enable_nat_gateway = true

  # for testing purposes, we only need a single NAT gateway now
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  tags = {
    Terraform = "true"
    Environment = local.env
  }
}