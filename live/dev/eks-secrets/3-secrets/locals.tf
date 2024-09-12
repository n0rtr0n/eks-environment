locals {
  cluster_name = data.terraform_remote_state.eks.outputs.eks_cluster_name
  env          = "dev"
  region       = "us-west-2"
}
