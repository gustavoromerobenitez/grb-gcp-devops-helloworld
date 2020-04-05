#########################################################
#
# Kubernetes Service
#
#########################################################
resource "kubernetes_service" "k8s-service" {
  metadata {
    name = "k8s-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment.k8s-deployment.metadata.0.labels.app
    }
    session_affinity = "ClientIP"

    port {
      port = 80
      target_port = var.container-port
      name = "http-port"
    }

    port {
      port = 443
      target_port = var.container-port
      name = "https-port"
    }

    type = "NodePort"

  }#spec

  depends_on = [ kubernetes_deployment.k8s-deployment ]
}
