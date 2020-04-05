#########################################################
#
# Kubernetes Ingress
#
#########################################################
resource "kubernetes_ingress" "k8s-ingress" {
  metadata {
    name = "k8s-ingress"
  }

  spec {
    backend {
      service_name = "k8s-service"
      service_port = 80
    }

    rule {
      http {
        path {
          backend {
            service_name = "k8s-service"
            service_port = 80
          }

          path = "/*"
        }
      }
    }

    # TODO Generate a certificate and store it as a K8s secret
    #tls {
    #  secret_name = "tls-secret"
    #}

  }#spec

  depends_on = [ kubernetes_service.k8s-service ]

}# Ingress
