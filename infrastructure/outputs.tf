output "google_project_current-project_number" {
  value = google_project.current-project.number
}

output "google_service_account_project-service-account_email" {
  value = google_service_account.project-service-account.email
}
output "google_service_account_project-service-account_name" {
  value = google_service_account.project-service-account.name
}
output "google_service_account_project-service-account_unique_id" {
  value = google_service_account.project-service-account.unique_id
}
output "google_service_account_project-service-account_account_id" {
  value = google_service_account.project-service-account.account_id
}

output "data_google_compute_default_service_account_default-compute-sa_email" {
  value = data.google_compute_default_service_account.default-compute-sa.email
}
