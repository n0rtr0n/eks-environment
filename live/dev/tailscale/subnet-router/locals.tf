locals {
  cidr_range = data.terraform_remote_state.vpc.outputs.vpc_cidr
  env        = "dev"
  region     = "us-west-2"
}
