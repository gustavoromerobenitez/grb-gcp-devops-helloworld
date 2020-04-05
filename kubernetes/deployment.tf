#########################################################
#
# Kubernetes Deployment
#
#########################################################

resource "kubernetes_deployment" "k8s-deployment" {

  metadata {
    name = "k8s-deployment"
    labels = {
      app = var.application-name
      terraform = "true"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.application-name
      }
    }

    template {
      metadata {
        labels = {
          app = var.application-name
        }
      }

      spec {

        service_account_name = "k8s-service-account"

        container {
          image = var.application-container-image
          name  = var.application-name

          env {
            name = "PORT"
            value = var.container-port
          }

          port {
            name = "http-port"
            container_port = var.container-port
          }

          resources {
            limits {
              cpu    = "1"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = var.container-port

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }# Liveness probe
        }# Container
      }# spec
    }# template
  }#spec

  depends_on = [ kubernetes_service_account.k8s-service-account ]
}
