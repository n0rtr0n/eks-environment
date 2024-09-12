module "eks_cluster" {
  source = "../../../modules/eks-cluster"

  cluster_admin_principal_arn = data.aws_caller_identity.current.arn
  eks_cluster_name            = "testing"
  eks_version                 = "1.30"
  env                         = "dev"
  instance_types              = ["t3.large"]
  private_subnets             = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  region                      = var.region
  worker_node_scaling_config = {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }
}
