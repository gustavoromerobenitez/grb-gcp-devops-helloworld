output "google_project_${var.project-name}_number" {
  value = google_project.${var.project-name}.number
}

output "google_project_iam_binding_iam_serviceaccountuser_etag" {
  value = google_project_iam_binding.iam_serviceaccountuser.etag
}

output "google_project_iam_binding_project_owner_etag" {
  value = google_project_iam_binding.project_owner.etag
}

output "google_project_iam_custom_role_BigQueryRO_role_id" {
  value = google_project_iam_custom_role.BigQueryRO.role_id
}

output "google_service_account_iaccore-rp-t1-int0_email" {
  value = google_service_account.iaccore-rp-t1-int0.email
}
output "google_service_account_iaccore-rp-t1-int0_name" {
  value = google_service_account.iaccore-rp-t1-int0.name
}
output "google_service_account_iaccore-rp-t1-int0_unique_id" {
  value = google_service_account.iaccore-rp-t1-int0.unique_id
}
output "google_service_account_iaccore-rp-t1-int0_account_id" {
  value = google_service_account.iaccore-rp-t1-int0.account_id
}

output "google_storage_bucket_${var.project-name}-server-secrets_name" {
  value = google_storage_bucket.${var.project-name}-server-secrets.name
}
output "google_storage_bucket_${var.project-name}-server-secrets_self_link" {
  value = google_storage_bucket.${var.project-name}-server-secrets.self_link
}
output "google_storage_bucket_${var.project-name}-server-secrets_url" {
  value = google_storage_bucket.${var.project-name}-server-secrets.url
}


output "google_storage_bucket_skyuk-uk-poc-iaccore-rp-t1-is-int0_name" {
  value = google_storage_bucket.skyuk-uk-poc-iaccore-rp-t1-is-int0.name
}
output "google_storage_bucket_skyuk-uk-poc-iaccore-rp-t1-is-int0_self_link" {
  value = google_storage_bucket.skyuk-uk-poc-iaccore-rp-t1-is-int0.self_link
}
output "google_storage_bucket_skyuk-uk-poc-iaccore-rp-t1-is-int0_url" {
  value = google_storage_bucket.skyuk-uk-poc-iaccore-rp-t1-is-int0.url
}
