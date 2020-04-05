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


data "google_compute_default_service_account" "default-compute-sa" {
  project = local.project-name

  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com, google_project_service.compute-googleapis-com]
}

resource "google_project_iam_member" "default-sa-storage-object-viewer-on-orchestrator" {
  project = "grb-gcp-devops"
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_compute_default_service_account.default-compute-sa.email}"
  provisioner "local-exec" { command = "sleep 10" }
  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com, google_project_service.compute-googleapis-com ]
}

resource "google_project_iam_member" "project-sa-storage-object-viewer-on-orchestrator" {
  project = "grb-gcp-devops"
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${var.project-service-account-name}@${local.project-name}.iam.gserviceaccount.com"
  provisioner "local-exec" { command = "sleep 10" }
  depends_on = [ google_project.current-project, google_project_service.iam-googleapis-com, google_project_service.compute-googleapis-com ]
}
