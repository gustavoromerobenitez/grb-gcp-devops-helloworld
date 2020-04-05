# gcpdevopshelloworld
A containerised Hello World! application created and deployed into GCP using Cloud Native services

Forked from [GoogleCloudPlatform/gke-gitops-tutorial-cloudbuild](https://github.com/GoogleCloudPlatform/gke-gitops-tutorial-cloudbuild)

This repository contains the code used in the
[GitOps-style Continuous Delivery with Cloud Build](https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build)
tutorial.

# Directory Structure
| Directory | Purpose |
| --- | --- |
| /application | Python HelloWorld application, and the CloudBuild build file that containerises it and upload the resulting image to Google Container Registry  |
| /application/*test*/*unit*/ | A basic unit test example that is run during application deployment |
| /builders | Code to build a CloudBuild Builder for Terraform  |
| /infrastructure  | Infrastructure definition in Terraform language, and CloudBuild build files to create and destroy |
| /infrastructure/*tfvars* | Environment-specific variables  |
| /images | Screenshots of the build process |


# Overview
This repository contains the Infrastructure-as-Code definition for a containerised HelloWorld application.

Using cloud-native GCP services has been a main priority. I've tried to create a solid infrastructure as code repository using as many GCP cloud-native technologies as possible. This is the reason why I have chosen CloudBuild over Jenkins and Groovy pipelines.

However instead of using Deployment Manager (Google's IaC Service), I have implemented the infrastructure in Terraform for now. The infrastructure has been defined in Terraform files with the remote state for each built project stored in a Storage Bucket in GCS in the orchestrating project, with versioning enabled.

There are three environment definitions for the infrastructure (dev,test,and prod) which in turn will be three separate GCP projects.

The application and infrastructure are built from a central orchestrating GCP project using [Google Cloud Build](https://cloud.google.com/cloud-build/docs/build-config?hl=en_GB ). CloudBuild is connected to Github via the [Google Cloud Build App](https://github.com/marketplace/google-cloud-build ) which handles the CloudBuild Triggers. At present builds are kicked off when changes are detected to specific files within the three main directories. In each case the corresponding cloudbuild*.yaml file is executed.

The build process uses many predefined *builders* but also includes a [Community Terraform Cloud Builder](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/terraform ) which has been built in the orchestrating project, using Terraform 0.12.20 and the code in the /builders directory.


# Pipelines

Pipelines are defined in cloudbuild*.yaml files are comprised of steps run in "builders" which purpose-specific containers.
These pipelines are triggered when certain changes are detected on the repository. These rules are specified in CloudBuild Triggers.

The application and Terraform builder have been built beforehand so the infrastructure build can pull them from the Container Registry in the orchestrating project.

# Limitations and Challenges

The GCP Free account does not create an Organization which prevents you from creating folders and also from having the projectCreator permission. Due to this limitation, despite the projects being defined in IaC, I had to manually create them and then import them into the terraform state.

The CloudBuild account in the orchestrator project has, by default, limited permissions, and it has been necessary to add additional permissions on the projects that were created by the Orchestrator project.

# ToDo

## DNS
I registered a domain called grbdevops.net and added CNAMEs but it does not seem to have worked and I haven't been able to troubleshoot this yet.

## Regional Cluster
The GKE cluster should be changed into regional:
- https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters

## Private Kubernetes Cluster
The Kubernetes cluster is not private at the moment. In order to be able to build from CLoudBuild, master_authorized_networks should be configured, and if that does not work, perhaps it would be required to use a Proxy as described in the following article:

https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters
https://cloud.google.com/solutions/creating-kubernetes-engine-private-clusters-with-net-proxies

## Terraform Modules
The GKE cluster creation could be converted into a terraform module
