locals {
  project-name="${var.project-base-name}-${var.environment}"
  project-state-bucket-prefix="terraform/${local.project-name}/state/"
  cluster-state-bucket-prefix="terraform/${local.project-name}/state/container-cluster"
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
    prefix = local.project-state-bucket-prefix
  }
}

data "terraform_remote_state" "container-cluster" {
  backend = "gcs"
  config = {
    bucket = var.remote-state-bucket
    prefix = local.cluster-state-bucket-prefix
  }
}

provider "google" {
  version = ">= 3.15"
  region  = "europe-west6"
  zone  = "europe-west6-a"
  # enable_batching = "false"
}

provider "kubernetes" {
  version = "~> 1.10"
  host = data.terraform_remote_state.container-cluster.outputs.google_container_cluster_container-cluster_endpoint
  insecure = "false"
  client_certificate = base64decode(data.terraform_remote_state.container-cluster.outputs.google_container_cluster_container-cluster_master_auth_0_client_certificate)
  client_key = base64decode(data.terraform_remote_state.container-cluster.outputs.google_container_cluster_container-cluster_master_auth_0_client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.container-cluster.outputs.google_container_cluster_container-cluster_master_auth_0_cluster_ca_certificate)
}

resource "google_project_service" "container-googleapis-com" {
  project = local.project-name
  service = "container.googleapis.com"
  disable_dependent_services = "true"
}
