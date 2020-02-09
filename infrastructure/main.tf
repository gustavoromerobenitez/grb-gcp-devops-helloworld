locals {
  project-name="${var.project-base-name}-${var.environment}"
  state-bucket-prefix="${var.remote-state-prefix}/${var.environment}/"
}

###############################################################################
#
# Providers
#
# Neither Variables nor Local references are allwed in the provider declaration
# which prevents this file from being fully parameterized.
#
# This file should be templated to avoid the limitations imposed by Terraform
###############################################################################
provider "google" {
  version = "~> 3.7"
  region  = "europe-west2"
  zone  = "europe-west2-a"
  # enable_batching = "false"
}

data "terraform_remote_state" "current-project" {
  backend = "gcs"
  config = {
    bucket = var.remote-state-bucket
    prefix = local.state-bucket-prefix
  }
}

provider "kubernetes" {
  version = "~> 1.10"
  host = google_container_cluster.container-cluster.endpoint
  insecure = "false"
  client_certificate = base64decode(google_container_cluster.container-cluster.master_auth.0.client_certificate)
  client_key = base64decode(google_container_cluster.container-cluster.master_auth.0.client_key)
  cluster_ca_certificate = base64decode(google_container_cluster.container-cluster.master_auth.0.cluster_ca_certificate)
}



resource "google_project" "current-project" {

  name = local.project-name
  project_id = local.project-name
  billing_account = var.billing-account
  skip_delete = "true"

  labels = {
    environment = var.environment
    terraform = "true"
  }

  provisioner "local-exec" { command = "sleep 60"  }
}

#########################################################
#
# Google APIs
#
#########################################################
resource "google_project_service" "iam-googleapis-com" {
  project = local.project-name
  service = "iam.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ google_project.current-project ]
}


resource "google_project_service" "storage-api-googleapis-com" {
  project = local.project-name
  service = "storage-api.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ google_project.current-project ]
}

resource "google_project_service" "container-googleapis-com" {
  project = local.project-name
  service = "container.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ google_project.current-project ]
}

resource "google_project_service" "containerregistry-googleapis-com" {
  project = local.project-name
  service = "containerregistry.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ google_project.current-project ]
}

resource "google_project_service" "compute-googleapis-com" {
  project = local.project-name
  service = "compute.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ google_project.current-project ]
}

resource "google_project_service" "dns-googleapis-com" {
  project = local.project-name
  service = "dns.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ google_project.current-project ]
}



#########################################################
#
# Service Accounts and Permissions
#
#########################################################
resource "google_service_account" "project-service-account" {
  project = local.project-name
  account_id = var.project-service-account-name
  display_name = var.project-service-account-name
  provisioner "local-exec" {  command = "sleep 10" }
  depends_on = [ google_project.current-project ]
}

resource "google_project_iam_member" "project-owner" {
  project = local.project-name
  role = "roles/owner"
  member = "serviceAccount:${var.project-service-account-name}@${local.project-name}.iam.gserviceaccount.com"
  provisioner "local-exec" { command = "sleep 10" }
  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com, google_service_account.project-service-account]
}

resource "google_project_iam_member" "automation-project-owner" {
  project = local.project-name
  role = "roles/owner"
  member = "serviceAccount:${var.automation-service-account}"
  provisioner "local-exec" { command = "sleep 10" }
  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com]
}


data "google_compute_default_service_account" "default-compute-sa" {
  project = local.project-name

  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com, google_project_service.compute-googleapis-com]
}

resource "google_project_iam_member" "storage-object-viewer" {
  project = "grb-gcp-devops"
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_compute_default_service_account.default-compute-sa.email}"
  provisioner "local-exec" { command = "sleep 10" }
  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com, google_project_service.compute-googleapis-com ]
}



#########################################################
#
# Network
#
#########################################################
resource "google_compute_subnetwork" "k8s-subnetwork" {

    name = var.container-cluster-subnetwork-name
    ip_cidr_range = var.container-cluster-cidr-range
    network = "default"
    project = local.project-name
    description = "Kubernetes Container Cluster Subnetwork for Pods and Services"
    private_ip_google_access = "false"
    secondary_ip_range = [
      {
        range_name = var.container-cluster-pods-secondary-range-name
        ip_cidr_range = var.container-cluster-pods-secondary-range-cidr
      },
      {
        range_name = var.container-cluster-services-secondary-range-name
        ip_cidr_range = var.container-cluster-services-secondary-range-cidr
      }
    ]

    depends_on = [ google_project.current-project, google_project_service.compute-googleapis-com ]
}



#########################################################
#
# Container Cluster
#
#########################################################

resource "google_container_cluster" "container-cluster" {

  project = local.project-name
  location = var.zone
  name = var.container-cluster-name
  network = "default"
  subnetwork = var.container-cluster-subnetwork-name

  remove_default_node_pool = true
  initial_node_count = 1

  ip_allocation_policy {
   cluster_secondary_range_name = var.container-cluster-pods-secondary-range-name
   services_secondary_range_name = var.container-cluster-services-secondary-range-name
  }

  maintenance_policy {
   daily_maintenance_window {
     start_time = "01:00"
   }
  }

  master_auth {
   # Leave username and password blank to disable Basic Authentication
   username = ""
   password = ""
   # Cient Certificate is considered a Legacy Authorisation method
   # Disable to avoid errors like: User \"client\" cannot create namespaces/secrets ...
   client_certificate_config {
     issue_client_certificate = "false"
   }
  }

  depends_on = [ google_project.current-project, google_project_service.container-googleapis-com, google_compute_subnetwork.k8s-subnetwork]

}



resource "google_container_node_pool" "primary_preemptible_nodes" {
  name = "default"
  project = local.project-name
  cluster = google_container_cluster.container-cluster.name
  initial_node_count = var.cluster-initial-node-count


  node_config {
    preemptible = true
    metadata = {
        disable-legacy-endpoints = "true"
      }
    disk_size_gb = var.cluster-node-disk-size-gb
    machine_type = var.cluster-node-machine-type
    oauth_scopes = [ "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring" ]
  }

  autoscaling {
     max_node_count = var.cluster-max-node-count
     min_node_count = var.cluster-min-node-count
  }

  management {
    auto_upgrade = "true"
    auto_repair = "true"
  }

  depends_on = [ google_project.current-project, google_project_service.container-googleapis-com, google_compute_subnetwork.k8s-subnetwork]
}



#########################################################
#
# Global Address
#
#########################################################
resource "google_compute_global_address" "global-address" {
  project = local.project-name
  name = "${var.environment}-global-address"
  description = "External IP address for the ${var.environment} environment Global HTTPS load balancer"
  address_type = "EXTERNAL"
  depends_on = [ google_project.current-project, google_project_service.compute-googleapis-com ]
}

#########################################################
#
# DNS Zone and A Record
#
#########################################################
resource "google_dns_managed_zone" "dns-zone" {
  project = local.project-name
  name = "grbdevops-net"
  dns_name = "grbdevops.net."
  description = "DNS zone"
  labels = {
    terraform = "true"
  }
  depends_on = [ google_project.current-project, google_project_service.dns-googleapis-com ]
}


resource "google_dns_record_set" "dns-a-record-set" {
  project = local.project-name
  name = google_dns_managed_zone.dns-zone.dns_name
  managed_zone = google_dns_managed_zone.dns-zone.name
  type = "A"
  ttl = "300"
  rrdatas = [ google_compute_global_address.global-address.address ]
  depends_on = [ google_project.current-project, google_project_service.dns-googleapis-com, google_project_service.compute-googleapis-com, google_dns_managed_zone.dns-zone, google_compute_global_address.global-address ]
}


resource "google_dns_record_set" "dns-cname-record-set" {
  project = local.project-name
  name = "leonteq-${var.environment}.${google_dns_managed_zone.dns-zone.dns_name}"
  managed_zone = google_dns_managed_zone.dns-zone.name
  type = "CNAME"
  ttl = "300"
  rrdatas = [ "leonteq-${var.environment}.${google_dns_managed_zone.dns-zone.dns_name}" ]
  depends_on = [ google_project.current-project, google_project_service.dns-googleapis-com, google_project_service.compute-googleapis-com, google_dns_managed_zone.dns-zone, google_compute_global_address.global-address ]
}




#########################################################
#
# Kubernetes Namespace
#
#########################################################
resource "kubernetes_namespace" "k8s-namespace" {
  metadata {
    annotations = {
      name = "k8s-namespace-${var.environment}"
    }

    labels = {
      terraform = "true"
    }

    name = "k8s-namespace"
  }
}


#########################################################
#
# Kubernetes Deployment
#
#########################################################

resource "kubernetes_deployment" "k8s-deployment" {

  metadata {
    name = "k8s-deployment"
    namespace = "k8s-namespace"
    labels = {
      app = var.application-name
      terraform = "true"
    }
  }

  spec {
    replicas = 3

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
        container {
          image = var.application-container-image
          name  = var.application-name

          port {
            name = "http-port"
            container_port = var.container-port
          }

          resources {
            limits {
              cpu    = "0.5"
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

  depends_on = [ google_project.current-project, google_project_service.compute-googleapis-com, google_container_cluster.container-cluster ]
}





#########################################################
#
# Kubernetes Service
#
#########################################################
resource "kubernetes_service" "k8s-service" {
  metadata {
    name = "k8s-service"
    namespace = "k8s-namespace"
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

  depends_on = [ google_project.current-project, google_project_service.compute-googleapis-com, google_container_cluster.container-cluster, kubernetes_deployment.k8s-deployment ]
}


#########################################################
#
# Kubernetes Ingress
#
#########################################################
resource "kubernetes_ingress" "k8s-ingress" {
  metadata {
    name = "k8s-ingress"
    namespace = "k8s-namespace"
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

  depends_on = [ google_project.current-project, google_project_service.compute-googleapis-com, google_container_cluster.container-cluster, kubernetes_service.k8s-service ]

}# Ingress





# OPTIONAL
#
# kubernetes_cluster_role_binding:
#   - provider: kubernetes
#     resource_types:
#       - resource_type: cluster_role_binding
#         resources:
#           - terraform_resource_name: "{{ KUBERNETES_SERVICE_ACCOUNT_NAME }}-binding"
#             metadata:
#               name: "{{ KUBERNETES_SERVICE_ACCOUNT_NAME }}-binding"
#             role_refs:
#               - kind: "ClusterRole"
#                 name: "cluster-admin"
#             subjects:
#               - kind: "ServiceAccount"
#                 name: "{{ KUBERNETES_SERVICE_ACCOUNT_NAME }}"
#                 namespace: "{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#             depends_on:
#               - "kubernetes_namespace.{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#
#
#
#
# kubernetes_service_account:
#   - provider: kubernetes
#     resource_types:
#       - resource_type: service_account
#         resources:
#           - name: "{{ KUBERNETES_SERVICE_ACCOUNT_NAME }}"
#             metadata:
#               name: "{{ KUBERNETES_SERVICE_ACCOUNT_NAME }}"
#               namespace: "{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#             automount_service_account_token: true
#             depends_on:
#               - "kubernetes_namespace.{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#
#
#




#
# resource "google_compute_ssl_certificate" "ssl-certificate" {
#     name = var.ssl-certificate-name
#     certificate = "file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PUBLIC_KEY_FILENAME }}\") "
#     private_key = "file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PRIVATE_KEY_FILENAME }}\") "
# }
