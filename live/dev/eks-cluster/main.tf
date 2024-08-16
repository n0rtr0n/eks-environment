data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}

data "aws_caller_identity" "current" {}

module "eks-cluster" {
  source = "../../../modules/eks-cluster"

  # TODO: for now, user creating the EKS cluster via Terraform will be cluster admin as well
  cluster_admin_principal_arn = data.aws_caller_identity.current.arn
  eks_cluster_name            = "testing"
  eks_version                 = "1.30"
  env                         = "dev"
  instance_types              = ["t3.large"]
  private_subnets             = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  region                      = "us-west-2"
}
