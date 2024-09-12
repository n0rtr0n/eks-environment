locals {
  env                  = "dev"
  cluster_name         = data.terraform_remote_state.eks.outputs.eks_cluster_name
  region               = "us-west-2"
  service_account_name = "external-secrets-${local.env}"
  secrets_namespace    = "external-secrets-${local.env}"
  oidc_arn             = data.terraform_remote_state.eks.outputs.eks_oidc_arn
  oidc_url             = data.aws_iam_openid_connect_provider.eks.url
}
