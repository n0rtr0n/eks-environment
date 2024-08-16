module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.12.1"

  name = "${var.vpc_name}-${var.env}"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # Internet Gateway for public subnets
  create_igw = true

  # DNS
  enable_dns_support   = true
  enable_dns_hostnames = true

  # since we have private subnets 
  enable_nat_gateway = true

  # for testing purposes, we only need a single NAT gateway now
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}
