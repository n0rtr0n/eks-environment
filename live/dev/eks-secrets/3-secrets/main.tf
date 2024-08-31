locals {
  cluster_name = data.terraform_remote_state.eks.outputs.eks_cluster_name
  env          = "dev"
  region       = "us-west-2"
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


data "terraform_remote_state" "external_secrets" {
  backend = "local"

  config = {
    path = "../1-external-secrets/terraform.tfstate"
  }
}

data "terraform_remote_state" "clustersecretstore" {
  backend = "local"

  config = {
    path = "../2-clustersecretstore/terraform.tfstate"
  }
}

data "terraform_remote_state" "ssm_secrets" {
  backend = "local"

  config = {
    path = "../../ssm-secrets/terraform.tfstate"
  }
}

data "aws_kms_alias" "default" {
  name = "alias/aws/ssm"
}

data "aws_ssm_parameter" "tailscale_api_key" {
  name = data.terraform_remote_state.ssm_secrets.outputs.tailscale_api_key_ssm_name
}

data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter*"
    ]
    resources = [data.aws_ssm_parameter.tailscale_api_key.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.default.arn]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name   = "external-secrets-${local.env}"
  policy = data.aws_iam_policy_document.external_secrets.json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = data.terraform_remote_state.external_secrets.outputs.external_secrets_iam_role_name
  policy_arn = aws_iam_policy.external_secrets.arn
}


# Tailscale API Key
resource "kubernetes_manifest" "tailscale" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "tailscale-api-key"
      namespace = "default"
    }
    spec = {
      secretStoreRef = {
        name = data.terraform_remote_state.clustersecretstore.outputs.clustersecretstore_name
        kind = "ClusterSecretStore"
      }
      refreshInterval = "60s" # is set to 0 to prevent from being automatically updated
      target = {
        name           = "tailscale"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "api-key"
          remoteRef = {
            key = data.aws_ssm_parameter.tailscale_api_key.name
          }
      }]
    }
  }
}
