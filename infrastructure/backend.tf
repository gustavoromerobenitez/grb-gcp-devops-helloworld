#
# Terraform docs re: configuring back end: https://www.terraform.io/docs/backends/types/gcs.html
#
# Versioning has been enabled on the bucket gs://grb-gcp-devops-terraform
# via the command gsutil versioning set on gs://grb-gcp-devops-terraform
#
terraform {
  backend "gcs" {
    bucket  = var.remote-state-bucket
    prefix  = var.remote-state-prefix
  }
}
