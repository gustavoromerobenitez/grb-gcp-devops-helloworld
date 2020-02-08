variable "project-name" {
  type    = "string"
  default = "${var.project-common-name}-${var.environment}"
}

variable "project-common-name" {
  type    = "string"
  default = "grb-gcp-devops-helloworld"
  description = "Project Common Name without the environment suffix"
}

variable "environment" {
  type    = "string"
  description = "The environment this project belongs to"
}

variable "region" {
  type    = "string"
  default = "europe-west2"
}

variable "zone"
{
  type = "string"
  default = "${var.region}-a"
}

variable "google-provider-version" {
  type = "string"
  default = "3.7.0"
}

variable "billing-account" {
  type = "string"
  default = "0177D8-2B9095-D16093" # SECRET Should be read from a bucket
}

variable "remote-state-bucket" {
  type = "string"
  default = "grb-gcp-devops-terraform"
}


variable "remote-state-prefix" {
  type = "string"
  default = "terraform/${var.project-name}/state/"
}

variable "project-service-account-name" {
  type = "string"
  default = "${var.project-name}"
}

variable "container-cluster-cidr-range" {
  type = "string"
}

variable "container-cluster-name" {
  type = "string"
  default = "${var.project-name}-k8s-cluster-1"
}

variable "container-cluster-subnetwork-name" {
  type = "string"
  default = "${var.project-name}-k8s-subnetwork"
}

variable "container-cluster-pods-secondary-range-name" {
  type = "string"
  default = "${var.project-name}-k8s-pods-secondary-range"
}

variable "container-cluster-pods-secondary-range-cidr" {
  type = "string"
}

variable "container-cluster-services-secondary-range-name" {
  type = "string"
  default = "${var.project-name}-k8s-services-secondary-range"
}

variable "container-cluster-services-secondary-range-cidr" {
  type = "string"
}


variable "cluster-node-machine-type" {
  type = "string"
  default = "n1-standard-1"
}

variable "cluster-max-node-count" {
  type = "string"
  default = "1"
}

variable "cluster-min-node-count" {
  type = "string"
  default = "1"
}

variable "cluster-initial-node-count" {
  type = "string"
  default = "1"
}

variable "cluster-node-disk-size-gb" {
  type = "string"
  default = "10"
}
