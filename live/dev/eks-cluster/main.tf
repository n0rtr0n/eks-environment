data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}

module "eks-cluster" {
  source = "../../../modules/eks-cluster"

  eks_cluster_name = "testing"
  eks_version      = "1.30"
  env              = "dev"
  instance_types   = ["t3.large"]
  private_subnets  = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  region           = "us-west-2"
}
