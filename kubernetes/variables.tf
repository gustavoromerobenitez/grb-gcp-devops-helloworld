variable "project-base-name" {
  type    = string
  description = "GCP Project Common Name without the environment suffix"
}

variable "environment" {
  type    = string
  description = "The environment this project belongs to"
}

variable "region" {
  type    = string
  default = "europe-west2"
  description = "The GCP region for the project"
}

variable "zone" {
  type = string
  default = "europe-west2-a"
  description = "The GCP zone for the compute resources"
}

variable "billing-account" {
  type = string
  default = "0177D8-2B9095-D16093" # SECRET Should be read from a bucket
  description = "The GCP Billing Account this project will be linked to"
}

variable "automation-service-account" {
  type    = string
  description = "The service account used by the atuomation"
}


variable "application-container-image" {
  type    = string
  description = "The full path in the Google Container registry to the container image that contains the application"
}

variable "container-port" {
  type    = string
  description = "The port that the application is listening on within the container"
}

variable "application-name" {
  type    = string
  description = "Friendly name for the application"
}



variable "remote-state-bucket" {
  type = string
  default = "grb-gcp-devops-terraform"
  description = "The Storage Bucket that will contain the Terraform State file for this project"
}


variable "remote-state-prefix" {
  type = string
  default = "terraform/state"
  description = "The path to the state file within the State Bucket"
}

variable "project-service-account-name" {
  type = string
  default = "project-default-sa"
  description = "The short name for the project's default service account, not to be confused with the compute default service account"
}


variable "k8s-service-account-name" {
  type = string
  description = "The Kubernetes service account name"
}
