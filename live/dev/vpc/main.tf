module "vpc" {
  source = "../../../modules/vpc"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  env             = "dev"
  vpc_cidr        = "10.0.0.0/16"
  vpc_name        = "eks-testing"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  region          = var.region
}
