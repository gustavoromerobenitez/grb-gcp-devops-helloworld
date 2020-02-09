variable "project-base-name" {
  type    = string
  default = "grb-gcp-devops-helloworld"
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

variable "google-provider-version" {
  type = string
  default = "3.7.0"
  description = "The Terraform Google Provider version"
}

variable "billing-account" {
  type = string
  default = "0177D8-2B9095-D16093" # SECRET Should be read from a bucket
  description = "The GCP Billing Account this project will be linked to"
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

variable "container-cluster-cidr-range" {
  type = string
  description = "The range of IP addresses assigned to the Container Cluster, in CIDR format"
}

variable "container-cluster-name" {
  type = string
  description = "The GCP Container Cluster name, that is the Managed Compute Instance group that will support the Kubernetes cluster"
}

variable "container-cluster-subnetwork-name" {
  type = string
  description = "The subnetwork that the Container Cluster will be attached to"
}

variable "container-cluster-pods-secondary-range-name" {
  type = string
  description = "The name of the Secondary IP Range that will be used to provide IP addresses to the Pods in the Kubernetes Cluster"
}

variable "container-cluster-pods-secondary-range-cidr" {
  type = string
  description = "The range of IP addresses, in CIDR format, that will be used to provide IP addresses to the Pods in the Kubernetes Cluster"
}

variable "container-cluster-services-secondary-range-name" {
  type = string
  description = "The name of the Secondary IP Range that will be used to provide IP addresses to the Services in the Kubernetes Cluster"
}

variable "container-cluster-services-secondary-range-cidr" {
  type = string
  description = "The range of IP addresses, in CIDR format, that will be used to provide IP addresses to the Services in the Kubernetes Cluster"
}


variable "cluster-node-machine-type" {
  type = string
  default = "n1-standard-1"
  description = "The Compute Instance type to be used for the nodes in the Container Cluster"
}

variable "cluster-max-node-count" {
  type = string
  default = "1"
  description = "The maximum number of nodes in the Container Cluster (only used if auto-scaling is enabled)"
}

variable "cluster-min-node-count" {
  type = string
  default = "1"
  description = "The minimum number of nodes in the Container Cluster (only used if auto-scaling is enabled)"
}

variable "cluster-initial-node-count" {
  type = string
  default = "1"
  description = "The initial number of nodes of the Container Cluster"
}

variable "cluster-node-disk-size-gb" {
  type = string
  default = "10"
  description = "The size in GB of the Container Cluster Nodes Persisten Disk"
}
