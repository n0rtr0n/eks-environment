data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  arn = local.oidc_arn
}
