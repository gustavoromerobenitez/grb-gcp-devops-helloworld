output "google_project_current-project_number" {
  value = google_project.current-project.number
}

output "google_container_cluster_container-cluster_master_auth_0_client_certificate" {
  value = google_container_cluster.container-cluster.master_auth.0.client_certificate
}

output "google_container_cluster_container-cluster_master_auth_0_client_key" {
  value = google_container_cluster.container-cluster.master_auth.0.client_key
}

output "google_container_cluster_container-cluster_master_auth_0_cluster_ca_certificate" {
  value = google_container_cluster.container-cluster.master_auth.0.cluster_ca_certificate
}

output "google_container_cluster_container-cluster_endpoint" {
  value = google_container_cluster.container-cluster.endpoint
}

output "google_container_cluster_container-cluster_name" {
  value = google_container_cluster.container-cluster.name
}

output "google_container_cluster_container-cluster_master_version" {
  value = google_container_cluster.container-cluster.master_version
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
