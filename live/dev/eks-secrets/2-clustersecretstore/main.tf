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

# This must be completed in a separate step because it relies on CRDs installed by the external-secrets operator 
# Getting an error: API did not recognize GroupVersionKind from manifest (CRD may not be installed)
resource "kubernetes_manifest" "ssm_parameterstore_clustersecretstore" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "external-secrets-clustersecretstore-${local.env}"
    }
    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = local.region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = data.terraform_remote_state.external_secrets.outputs.external_secrets_service_account
                namespace = data.terraform_remote_state.external_secrets.outputs.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  }
}
