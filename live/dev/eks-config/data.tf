data "aws_caller_identity" "current" {}

data "aws_lb_hosted_zone_id" "this" {}

data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

data "aws_route53_zone" "this" {
  name = local.domain_name
}
