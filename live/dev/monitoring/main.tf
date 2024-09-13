resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = local.namespace
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.id
  version    = "62.3.1"
  values     = [file("${path.module}/prometheus-stack.yml")]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = kubernetes_namespace_v1.monitoring.id
  version    = "2.10.2"
  values     = [file("${path.module}/loki-stack.yml")]
}
