terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.62"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}

data "terraform_remote_state" "global" {
  backend = "local"

  config = {
    path = "../../global/terraform.tfstate"
  }
}

data "aws_lb_hosted_zone_id" "this" {}
locals {
  cluster_name                       = data.terraform_remote_state.eks.outputs.eks_cluster_name
  domain_name                        = var.domain_name
  env                                = "dev"
  load_balancer_hostname             = kubernetes_ingress_v1.applications.status.0.load_balancer.0.ingress.0.hostname
  namespace                          = kubernetes_namespace_v1.applications.metadata[0].name
  region                             = var.region
  prime_generator_python_app_name    = "prime-generator-python"
  prime_generator_python_domain_name = "${local.prime_generator_python_app_name}.${local.domain_name}"
  public_subnet_ids                  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
}

data "aws_eks_cluster" "this" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

provider "aws" {
  region = local.region
}

# this allows us to authenticate to the k8s cluster directly through the IAM user running the Terraform
# one less secret to manage!
# requires AWS CLI
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

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  values = [file("${path.module}/config/metrics-server.yaml")]
}

# Pod identity

# for available versions, run:
# aws eks describe-addon-verions --region us-west-2 --addon-name eks-pod-identity-agent
resource "aws_eks_addon" "pod_identity" {
  cluster_name  = data.aws_eks_cluster.this.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.0-eksbuild.1"
}

data "aws_iam_policy_document" "cluster_autoscaler_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${data.aws_eks_cluster.this.name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_trust.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"] # TODO: restrict actions to more specific resources
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "${data.aws_eks_cluster.this.name}-cluster-autoscaler"
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = data.aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

resource "helm_release" "cluster_autoscaler" {
  name = "autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = data.aws_eks_cluster.this.name
  }

  set {
    name  = "awsRegion"
    value = local.region
  }
}

resource "kubernetes_namespace_v1" "applications" {
  metadata {
    name = "applications-${local.env}"
  }
}

resource "helm_release" "prime_generator_python" {
  name = "prime-generator-python"

  repository = "./../../../charts"
  chart      = "prime-generator-python"
  version    = "0.1.0"

  set {
    name  = "image.name"
    value = data.terraform_remote_state.global.outputs.prime_generator_python_ecr_url
  }
  set {
    name  = "namespace"
    value = "applications-${local.env}"
  }
}


data "aws_route53_zone" "this" {
  name = local.domain_name
}

resource "aws_route53_record" "prime_generator_python" {
  zone_id = data.aws_route53_zone.this.id
  name    = local.prime_generator_python_domain_name
  type    = "A"

  alias {
    name                   = local.load_balancer_hostname
    zone_id                = data.aws_lb_hosted_zone_id.this.id
    evaluate_target_health = true
  }
}

resource "kubernetes_ingress_v1" "applications" {
  wait_for_load_balancer = true
  metadata {
    name      = local.namespace
    namespace = local.namespace
    annotations = {
      "alb.ingress.kubernetes.io/scheme"  = "internet-facing"
      "alb.ingress.kubernetes.io/subnets" = join(",", local.public_subnet_ids)
    }
  }
  spec {
    ingress_class_name = "alb"

    rule {
      host = local.prime_generator_python_domain_name
      http {
        path {
          backend {
            service {
              name = local.prime_generator_python_app_name
              port {
                number = 80
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
  }
}
