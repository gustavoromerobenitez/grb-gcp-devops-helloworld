locals {
  project-name="${var.project-base-name}-${var.environment}"
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
provider "google" {
  version = ">= 3.15"
  region  = "europe-west2"
  zone  = "europe-west2-a"
  # enable_batching = "false"
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
