resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = var.labels
  }
  spec {
    replicas = var.replica_count
    selector {
      match_labels = var.labels
    }
    template {
      metadata {
        labels = var.labels
      }
      spec {
        container {
          name  = var.name
          image = "${var.image_name}:${var.image_tag}"
          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }
  spec {
    type     = "NodePort"
    selector = var.labels
    port {
      protocol    = "TCP"
      port        = var.service_port
      target_port = var.container_port
    }
  }
}
