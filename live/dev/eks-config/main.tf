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

data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
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
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role.json
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

module "prime_generator_python" {
  source = "../../../modules/app"

  name           = local.prime_generator_python_app_name
  namespace      = local.namespace
  image_name     = data.terraform_remote_state.global.outputs.prime_generator_python_ecr_url
  image_tag      = "latest"
  container_port = 8888
  service_port   = 80
  labels = {
    app  = local.prime_generator_python_app_name
    tier = "backend"
  }
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

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = local.domain_name
  zone_id     = data.aws_route53_zone.this.id

  validation_method = "DNS"

  subject_alternative_names = [
    local.prime_generator_python_domain_name,
  ]

  wait_for_validation = true

  tags = {
    Name = local.domain_name
  }
}

# The ALB seems to stick around even after the helm release is deleted
# You may need to manually delete the ALB when tearing down the environment?
resource "kubernetes_ingress_v1" "applications" {
  wait_for_load_balancer = true
  metadata {
    name      = local.namespace
    namespace = local.namespace
    annotations = {
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/subnets"              = join(",", local.public_subnet_ids)
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
      "alb.ingress.kubernetes.io/certificate-arn"      = module.acm.acm_certificate_arn
    }
  }
  spec {
    ingress_class_name = "alb"
    tls {
      hosts = [local.prime_generator_python_domain_name]
    }

    rule {
      host = local.prime_generator_python_domain_name
      http {
        path {
          backend {
            service {
              name = "ssl-redirect"
              port {
                name = "use-annotation"
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
        path {
          backend {
            service {
              name = module.prime_generator_python.service_name
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

