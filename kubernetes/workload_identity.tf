# Error required attribute project not set for service account resource
#module "workload-identity" {
#  source  = "Brindster/workload-identity/google"
#  version = "1.0.0"
#  # insert the 4 required variables here
#  namespace = "default" # Description: Kubernetes namespace of the service account to grant permissions to
#  project = local.project-name
#  roles = [ "roles/owner" ] # List of Roles to assign to the service account
#  service_account = var.k8s-service-account-name # Description: Kubernetes service account to grant permissions to
#}

#
# Error: Error applying IAM policy for service account 'projects/k8s-tf-dev/serviceAccounts/k8s-service-account@k8s-tf-dev.iam.gserviceaccount.com': Error setting IAM policy for service account 'projects/k8s-tf-dev/serviceAccounts/k8s-service-account@k8s-tf-dev.iam.gserviceaccount.com': googleapi: Error 400: Identity namespace does not exist (k8s-tf-dev.svc.id.goog)., badRequest
#
#  on .terraform/modules/kubernetes-engine_workload-identity/terraform-google-kubernetes-engine-7.3.0/modules/workload-identity/main.tf line 61, in resource "google_service_account_iam_member" "main":
#  61: resource "google_service_account_iam_member" "main" {
#
#module "kubernetes-engine_workload-identity" {
#  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
#  version = "7.3.0"
#  name = var.k8s-service-account-name
#  project_id = local.project-name
#  k8s_sa_name = var.k8s-service-account-name
#  use_existing_k8s_sa = true
#  namespace = "default"
#}

# TODO  Assign permissions to the created Google Service Account to allow K8s to access resources
