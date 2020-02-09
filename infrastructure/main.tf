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

#provider "kubernetes" {
#
#  host = "data.terraform_remote_state.${local.project-name}.google_container_cluster_var.container-cluster-name_endpoint"
#  insecure = "false"
#  client_certificate = "base64decode(data.terraform_remote_state.${local.project-name}.google_container_cluster_var.container-cluster-name_master_auth_0_client_certificate)"
#  client_key = "base64decode(data.terraform_remote_state.${local.project-name}.google_container_cluster_var.container-cluster-name_master_auth_0_client_key)"
#  cluster_ca_certificate = "base64decode(data.terraform_remote_state.${local.project-name}.google_container_cluster_var.container-cluster-name_master_auth_0_cluster_ca_certificate)"
#
#}


data "terraform_remote_state" "current-project" {
  backend = "gcs"
  config = {
    bucket = var.remote-state-bucket
    prefix = local.state-bucket-prefix
  }
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
  name = "${var.environment}-grb-gcp-devops-com"
  dns_name = "${var.environment}.grb-gcp-devops.com."
  description = "${var.environment} DNS zone"
  labels = {
    terraform = "true"
  }
  depends_on = [ google_project.current-project, google_project.current-project, google_project_service.compute-googleapis-com ]
}


resource "google_dns_record_set" "dns-record-set" {
  project = local.project-name
  name = "leonteq.${google_dns_managed_zone.dns-zone.dns_name}"
  managed_zone = google_dns_managed_zone.dns-zone.name
  type = "A"
  ttl = "300"
  rrdatas = [ google_compute_global_address.global-address.address ]
  depends_on = [ google_project.current-project, google_dns_managed_zone.dns-zone, google_compute_global_address.global-address]
}





#########################################################
#
# Kubernetes (Service, Deployment, Service Account)
#
#########################################################
# kubernetes_service:
#   - provider: kubernetes
#     resource_types:
#     - resource_type: service
#       resources:
#
#         - name: "{{ KUBERNETES_JENKINS_UI_SERVICE_NAME }}"
#           metadata:
#             name: "{{ KUBERNETES_JENKINS_UI_SERVICE_NAME }}"
#             namespace: "{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#             annotations:
#               - name: "cloud.google.com/app-protocols"
#                 value: "{ \\\"{{ KUBERNETES_JENKINS_UI_SERVICE_HTTPS_PORT_NAME }}\\\":\\\"HTTPS\\\" }"
#           spec:
#             type: NodePort
#             cluster_ip: "{{ KUBERNETES_JENKINS_UI_SERVICE_CLUSTER_IP_ADDRESS }}"
#             selector:
#               - name: "app"
#                 value: "jenkins-master-{{ JENKINS_IMAGE_VERSION | regex_replace('\\.', '-') }}"
#             ports:
#               - protocol: "TCP"
#                 port: "{{ JENKINS_FRONTEND_PORT }}"
#                 target_port: "{{ JENKINS_CONTAINER_HTTPS_PORT }}"
#                 name: "{{ KUBERNETES_JENKINS_UI_SERVICE_HTTPS_PORT_NAME }}"
#           depends_on:
#             - "kubernetes_namespace.{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#             - "kubernetes_deployment.{{ KUBERNETES_DEPLOYMENT_NAME }}"
#
#         - name: "{{ KUBERNETES_JENKINS_DISCOVERY_SERVICE_NAME }}"
#           metadata:
#             name: "{{ KUBERNETES_JENKINS_DISCOVERY_SERVICE_NAME }}"
#             namespace: "{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#           spec:
#             type: ClusterIP
#             cluster_ip: "{{ KUBERNETES_JENKINS_DISCOVERY_SERVICE_CLUSTER_IP_ADDRESS }}"
#             selector:
#               - name: "app"
#                 value: "jenkins-master-{{ JENKINS_IMAGE_VERSION | regex_replace('\\.', '-') }}"
#             ports:
#               - protocol: TCP
#                 port: "{{ JENKINS_DISCOVERY_PORT }}"
#                 target_port: "{{ JENKINS_DISCOVERY_PORT }}"
#                 name: executors
#             depends_on:
#               - "kubernetes_namespace.{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#               - "kubernetes_deployment.{{ KUBERNETES_DEPLOYMENT_NAME }}"
#               - "kubernetes_service.{{ KUBERNETES_JENKINS_UI_SERVICE_NAME }}"
#
#
#
# kubernetes_namespace:
#   - provider: kubernetes
#     resource_types:
#       - resource_type: namespace
#         resources:
#
#           - name: "{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#             metadata:
#               annotations:
#                 - name: "name"
#                   value: "{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#               name: "{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#             outputs: []
#
#           - name: "{{ KUBERNETES_NAMESPACE_JENKINS_EXECUTOR }}"
#             metadata:
#               annotations:
#                 - name: "name"
#                   value: "{{ KUBERNETES_NAMESPACE_JENKINS_EXECUTOR }}"
#               name: "{{ KUBERNETES_NAMESPACE_JENKINS_EXECUTOR }}"
#             outputs: []
#
#
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
# kubernetes_deployment:
#   - provider: kubernetes
#     resource_types:
#       - resource_type: deployment
#         resources:
#           - name: "{{ KUBERNETES_DEPLOYMENT_NAME }}"
#             metadata:
#               name: "{{ KUBERNETES_DEPLOYMENT_NAME }}"
#               namespace: "{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#               labels:
#                 - name: "app"
#                   value: "jenkins-master-{{ JENKINS_IMAGE_VERSION | regex_replace('\\.', '-') }}"
#             spec:
#               replicas: 1
#               min_ready_seconds: "120"
#               selector:
#                 match_labels:
#                   - name: "app"
#                     value: "jenkins-master-{{ JENKINS_IMAGE_VERSION | regex_replace('\\.', '-') }}"
#               template:
#                 metadata:
#                   labels:
#                     - name: "app"
#                       value: "jenkins-master-{{ JENKINS_IMAGE_VERSION | regex_replace('\\.', '-') }}"
#                 spec:
#                   service_account_name: "{{ KUBERNETES_SERVICE_ACCOUNT_NAME }}"
#                   volumes:
#                     - name: "{{ KUBERNETES_SECRET_VOLUME_NAME }}"
#                       secret:
#                         secret_name: "{{ KUBERNETES_SERVICE_ACCOUNT_SECRET_NAME }}"
#                         default_mode: "0444"
#                     - name: "{{ KUBERNETES_PERSISTENT_VOLUME_NAME }}"
#                       persistent_volume_claim:
#                         claim_name: "{{ KUBERNETES_PERSISTENT_VOLUME_CLAIM_NAME }}"
#                         read_only: "false"
#                   containers:
#                     - name: "jenkins-master-{{ JENKINS_IMAGE_VERSION | regex_replace('\\.', '-') }}"
#                       image: "{{ JENKINS_MASTER_IMAGE_NAME }}"
#                       volume_mounts:
#                         - name: "{{ KUBERNETES_SECRET_VOLUME_NAME }}"
#                           read_only: "true"
#                           mount_path: "{{ KUBERNETES_SECRET_VOLUME_MOUNT_POINT }}"
#                         - name: "{{ KUBERNETES_PERSISTENT_VOLUME_NAME }}"
#                           read_only: "false"
#                           mount_path: "{{ KUBERNETES_PERSISTENT_VOLUME_MOUNT_POINT }}"
#                       ports:
#                         - name: https-port
#                           container_port: "{{ JENKINS_CONTAINER_HTTPS_PORT }}"
#                         - name: executor-port
#                           container_port: "{{ JENKINS_DISCOVERY_PORT }}"
#                       readiness_probe:
#                         http_get:
#                           path: /login
#                           port: "{{ JENKINS_CONTAINER_HTTPS_PORT }}"
#                           scheme: HTTPS
#                         initial_delay_seconds: 120
#                         period_seconds: 30
#                         timeout_seconds: 30
#                         success_threshold: 2
#                         failure_threshold: 10
#                       resources:
#                         limits:
#                           cpu: 500m
#                           memory: 1500Mi
#                         requests:
#                           cpu: 500m
#                           memory: 1500Mi
#             depends_on:
#               - "google_storage_bucket_object.{{ JENKINS_CONFIG_BUCKET_OBJECT_NAME }}"
#               - "kubernetes_service_account.{{ KUBERNETES_SERVICE_ACCOUNT_NAME }}"
#               - "kubernetes_namespace.{{ KUBERNETES_NAMESPACE_JENKINS_MASTER }}"
#               - "kubernetes_persistent_volume_claim.{{ KUBERNETES_PERSISTENT_VOLUME_CLAIM_NAME }}"
#               - "kubernetes_storage_class.{{ KUBERNETES_STORAGE_CLASS_NAME }}"





#
# resource "google_compute_ssl_certificate" "ssl-certificate" {
#     name = var.ssl-certificate-name
#     certificate = "file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PUBLIC_KEY_FILENAME }}\") "
#     private_key = "file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PRIVATE_KEY_FILENAME }}\") "
# }
