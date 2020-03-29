locals {
  project-name="${var.project-base-name}-${var.environment}"
  state-bucket-prefix="terraform/${local.project-name}/state/"
}

###############################################################################
#
# Providers
#
# Neither Variables nor Local references are allowed in the provider declaration
# which prevents this file from being fully parameterized.
#
# This file should be templated to avoid the limitations imposed by Terraform
###############################################################################


data "terraform_remote_state" "current-project" {
  backend = "gcs"
  config = {
    bucket = var.remote-state-bucket
    prefix = local.state-bucket-prefix
  }
}

provider "kubernetes" {
  version = "~> 1.10"
  host = data.terraform_remote_state.current-project.outputs.google_container_cluster_container-cluster_endpoint
  insecure = "false"
  client_certificate = base64decode(data.terraform_remote_state.current-project.outputs.google_container_cluster_container-cluster_master_auth_0_client_certificate)
  client_key = base64decode(data.terraform_remote_state.current-project.outputs.google_container_cluster_container-cluster_master_auth_0_client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.current-project.outputs.google_container_cluster_container-cluster_master_auth_0_cluster_ca_certificate)
}

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
      port = var.container-port
      target_port = 80
    }

    port {
      port = var.container-port
      target_port = 443
    }

    type = "NodePort"

  }#spec

  depends_on = [ kubernetes_deployment.k8s-deployment ]
}


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
      service_port = var.container-port
    }

    rule {
      http {
        path {
          backend {
            service_name = "k8s-service"
            service_port = var.container-port
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




resource "kubernetes_service_account" "k8s-service-account" {
  metadata {
    name = var.k8s-service-account-name
  }

  automount_service_account_token = "true"
}


# Error required attribute project not set for service account resource
#module "workload-identity" {
#  source  = "Brindster/workload-identity/google"
#  version = "1.0.0"
#  # insert the 4 required variables here
#  namespace = "default" # Description: Kubernetes namespace of the service account to grant permissions to
#  project = local.project-name
#  roles = [ "roles/owner" ] # List of Roles to assign to the service account
#  service_account = var.k8s-service-account-name # Description: Kubernetes service account to grant permissions to
#}

module "kubernetes-engine_workload-identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "7.3.0"
  name = var.k8s-service-account-name
  project_id = local.project-name
  k8s_sa_name = var.k8s-service-account-name
  use_existing_k8s_sa = true
  namespace = "default"
}

# TODO  Assign permissions to the created Google Service Account to allow K8s to access resources

resource "kubernetes_role_binding" "k8s-role-binding" {
  metadata {
    name      = "k8s-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.k8s-service-account-name
  }
  subject {
    kind      = "User"
    name      = data.terraform_remote_state.current-project.outputs.google_service_account_project-service-account_email
  }
  subject {
    kind = "User"
    name = var.automation-service-account
  }

}
