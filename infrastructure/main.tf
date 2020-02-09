locals {
  project-name="${var.project-base-name}-${var.environment}"
  state-bucket-prefix="${var.remote-state-prefix}/${var.environment}/"
}


# Neither Variables nor Local references are allwed in the provider declaration
# which prevents this file from being fully parameterized.
#
# This file should be templated to avoid the limitations imposed by Terraform
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


resource "google_project_iam_member" "project-owner" {
  project = local.project-name
  role = "roles/owner"
  member = "serviceAccount:${var.project-service-account-name}@${local.project-name}.iam.gserviceaccount.com"
  provisioner "local-exec" { command = "sleep 10" }
  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com]
}

resource "google_project_iam_member" "automation-project-owner" {
  project = local.project-name
  role = "roles/owner"
  member = "serviceAccount:${var.automation-service-account}"
  provisioner "local-exec" { command = "sleep 10" }
  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com]
}



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


resource "google_service_account" "project-service-account" {
  project = local.project-name
  account_id = var.project-service-account-name
  display_name = var.project-service-account-name
  provisioner "local-exec" {  command = "sleep 10" }
  depends_on = [ google_project_iam_binding.project-owner, google_project.current-project ]
}



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



#
# resource "google_compute_ssl_certificate" "ssl-certificate" {
#     name = var.ssl-certificate-name
#     certificate = "file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PUBLIC_KEY_FILENAME }}\") "
#     private_key = "file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PRIVATE_KEY_FILENAME }}\") "
# }
