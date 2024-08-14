locals {
  cluster_name = "eks-testing-${local.env}"
  eks_version  = "1.30"
}

# IAM 
data "aws_iam_policy_document" "eks-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks" {
  name               = "eks-cluster-testing-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.eks-assume_role.json
}

# TODO: customize to restrict the permissions of this role
resource "aws_iam_role_policy_attachment" "eks-cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

# TODO: customize to restrict the permissions of this role
resource "aws_iam_role_policy_attachment" "eks-cluster-vpc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}

# for learning purposes, provisining all resources instead of using all-inclusive module
resource "aws_eks_cluster" "testing" {
  name     = local.cluster_name
  version  = local.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    subnet_ids              = module.vpc.private_subnets
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }
}
