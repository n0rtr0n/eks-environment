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
  name               = "${var.eks_cluster_name}-${var.env}"
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

data "aws_caller_identity" "current" {}

# kms key policy
data "aws_iam_policy_document" "kms_eks_key" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "eks" {
  description         = "KMS Key for EKS cluster"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_eks_key.json
}


data "aws_iam_policy_document" "kms_eks" {
  statement {
    effect = "Allow"
    actions = [
      "kms:List*",
      "kms:Describe*",
      "kms:CreateGrant",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
    ]
    resources = [aws_kms_key.eks.arn]
  }
}

resource "aws_iam_policy" "kms_eks" {
  name   = "kms-eks-${var.env}"
  policy = data.aws_iam_policy_document.kms_eks.json
}

resource "aws_iam_role_policy_attachment" "kms_eks" {
  role       = aws_iam_role.eks.name
  policy_arn = aws_iam_policy.kms_eks.arn
}

# for learning purposes, provisining all resources instead of using all-inclusive module
resource "aws_eks_cluster" "this" {
  name     = "${var.eks_cluster_name}-${var.env}"
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    subnet_ids              = var.private_subnets
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }
}

# an EKS Access Entry is automatically created for this user through
# the bootstrap_cluster_creator_admin_permissions above
resource "aws_eks_access_policy_association" "readonly" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.cluster_admin_principal_arn

  access_scope {
    type = "cluster"
  }
}
