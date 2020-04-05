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


#data "terraform_remote_state" "current-project" {
#  backend = "gcs"
#  config = {
#    bucket = var.remote-state-bucket
#    prefix = local.state-bucket-prefix
#  }
#}

provider "google" {
  version = ">= 3.15"
  region  = "europe-west2"
  zone  = "europe-west2-a"
  # enable_batching = "false"
}

provider "kubernetes" {
  version = "~> 1.10"
  host = google_container_cluster.container-cluster.endpoint
  insecure = "false"
  client_certificate = base64decode(google_container_cluster.container-cluster.master_auth.0.client_certificate)
  client_key = base64decode(google_container_cluster.container-cluster.master_auth.0.client_key)
  cluster_ca_certificate = base64decode(google_container_cluster.container-cluster.master_auth.0.cluster_ca_certificate)
}

resource "google_project_service" "container-googleapis-com" {
  project = local.project-name
  service = "container.googleapis.com"
  disable_dependent_services = "true"
}
