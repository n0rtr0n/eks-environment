locals {
  env                  = "dev"
  cluster_name         = data.terraform_remote_state.eks.outputs.eks_cluster_name
  region               = "us-west-2"
  service_account_name = "external-secrets-${local.env}"
  secrets_namespace    = "external-secrets-${local.env}"
  oidc_arn             = data.terraform_remote_state.eks.outputs.eks_oidc_arn
  oidc_url             = data.aws_iam_openid_connect_provider.eks.url
}

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../../eks-cluster/terraform.tfstate"
  }
}

data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  arn = local.oidc_arn
}

provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.id]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.this.id]
      command     = "aws"
    }
  }
}

data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(local.oidc_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(local.oidc_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.secrets_namespace}:${local.service_account_name}"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "external-secrets-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json
}


resource "kubernetes_namespace_v1" "secrets" {
  metadata {
    name = local.secrets_namespace
  }
}

resource "kubernetes_service_account_v1" "secrets" {
  metadata {
    name      = local.service_account_name
    namespace = kubernetes_namespace_v1.secrets.id
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets.arn
    }
  }
}

# operator for external secrets
resource "helm_release" "external_secrets" {
  name = "external-secrets"

  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = kubernetes_namespace_v1.secrets.id
  version          = "0.10.0"
  create_namespace = false

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "webhook.port"
    value = "9443"
  }
}
