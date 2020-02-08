provider "google" {
  project = "grb-gcp-devops-leonteq-terraform"
  version = "2.19.0"
  region = "europe-west1"
}

provider "kubernetes" {

  host = "${data.terraform_remote_state.grb-gcp-devops-leonteq-terraform.google_container_cluster_{{ CONTAINER_CLUSTER_NAME }}_endpoint}"
  insecure = "false"
  client_certificate = "${base64decode(data.terraform_remote_state.grb-gcp-devops-leonteq-terraform.google_container_cluster_{{ CONTAINER_CLUSTER_NAME }}_master_auth_0_client_certificate)}"
  client_key = "${base64decode(data.terraform_remote_state.grb-gcp-devops-leonteq-terraform.google_container_cluster_{{ CONTAINER_CLUSTER_NAME }}_master_auth_0_client_key)}"
  cluster_ca_certificate = "${base64decode(data.terraform_remote_state.grb-gcp-devops-leonteq-terraform.google_container_cluster_{{ CONTAINER_CLUSTER_NAME }}_master_auth_0_cluster_ca_certificate)}"

}


data "terraform_remote_state" "grb-gcp-devops-leonteq-terraform" {
  backend = "gcs"
  config = {
    bucket = "skyuk-uk-tf-state"
    prefix = "terraform/grb-gcp-devops-leonteq-terraform//state"
  }
}


resource "google_project" "grb-gcp-devops-leonteq-terraform" {
  name = "grb-gcp-devops-leonteq-terraform"
  project_id = "grb-gcp-devops-leonteq-terraform"
  billing_account = "0177D8-2B9095-D16093"

  skip_delete = "true"

  labels = {
    environment = "demo"
    git_repo_name = "gcpdevopshelloworld"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

}

output "google_project_grb-gcp-devops-leonteq-terraform_number" {
  value = google_project.grb-gcp-devops-leonteq-terraform.number
}


resource "google_project_iam_binding" "iam_serviceaccountuser" {
  project = "grb-gcp-devops-leonteq-terraform"

  role = "roles/iam.serviceAccountUser"
  members = [ "serviceAccount:tds-ops@skyuk-platform-engineering.iam.gserviceaccount.com" ]

  provisioner "local-exec" {
    command = "sleep 10"
  }

  depends_on = [google_project.grb-gcp-devops-leonteq-terraform, google_project_service.compute-googleapis-com, google_project_service.oslogin-googleapis-com, google_project_service.logging-googleapis-com, google_project_service.monitoring-googleapis-com, google_project_service.iam-googleapis-com, google_project_service.bigquery-json-googleapis-com, google_project_service.sourcerepo-googleapis-com, google_project_service.cloudkms-googleapis-com, google_project_service.storage-api-googleapis-com, google_project_service.iamcredentials-googleapis-com, google_project_service.cloudresourcemanager-googleapis-com, google_project_service.datacatalog-googleapis-com, google_project_service.bigquerystorage-googleapis-com, google_project_service.pubsub-googleapis-com]
}

output "google_project_iam_binding_iam_serviceaccountuser_etag" {
  value = google_project_iam_binding.iam_serviceaccountuser.etag
}


resource "google_project_iam_binding" "project_owner" {
  project = "grb-gcp-devops-leonteq-terraform"

  role = "roles/owner"
  members = [ "serviceAccount:terraform-ops@skyuk-uk-dto-terraform-prod.iam.gserviceaccount.com" ]

  provisioner "local-exec" {
    command = "sleep 10"
  }

  depends_on = [google_project.grb-gcp-devops-leonteq-terraform, google_project_service.compute-googleapis-com, google_project_service.oslogin-googleapis-com, google_project_service.logging-googleapis-com, google_project_service.monitoring-googleapis-com, google_project_service.iam-googleapis-com, google_project_service.bigquery-json-googleapis-com, google_project_service.sourcerepo-googleapis-com, google_project_service.cloudkms-googleapis-com, google_project_service.storage-api-googleapis-com, google_project_service.iamcredentials-googleapis-com, google_project_service.cloudresourcemanager-googleapis-com, google_project_service.datacatalog-googleapis-com, google_project_service.bigquerystorage-googleapis-com, google_project_service.pubsub-googleapis-com]

}

output "google_project_iam_binding_project_owner_etag" {
  value = google_project_iam_binding.project_owner.etag
}



resource "google_project_iam_custom_role" "BigQueryRO" {
  role_id = "BigQueryRO"
  title = "BigQuery RO"
  permissions = [ "bigquery.datasets.get", "bigquery.datasets.getIamPolicy", "bigquery.tables.get", "bigquery.tables.getData", "bigquery.tables.list", "resourcemanager.projects.get" ]



  description = "BigQuery Data Viewer role without export"


  provisioner "local-exec" {
    command = "sleep 10"
  }

  depends_on = [google_project.grb-gcp-devops-leonteq-terraform, google_project_service.compute-googleapis-com, google_project_service.oslogin-googleapis-com, google_project_service.logging-googleapis-com, google_project_service.monitoring-googleapis-com, google_project_service.iam-googleapis-com, google_project_service.bigquery-json-googleapis-com, google_project_service.sourcerepo-googleapis-com, google_project_service.cloudkms-googleapis-com, google_project_service.storage-api-googleapis-com, google_project_service.iamcredentials-googleapis-com, google_project_service.cloudresourcemanager-googleapis-com, google_project_service.datacatalog-googleapis-com, google_project_service.bigquerystorage-googleapis-com, google_project_service.pubsub-googleapis-com]
}

output "google_project_iam_custom_role_BigQueryRO_role_id" {
  value = google_project_iam_custom_role.BigQueryRO.role_id
}




resource "google_project_service" "iam-googleapis-com" {
  project = "grb-gcp-devops-leonteq-terraform"
  service = "iam.googleapis.com"

  disable_dependent_services = true

  provisioner "local-exec" {
         command = "sleep 60"
  }
}


resource "google_project_service" "storage-api-googleapis-com" {
  project = "grb-gcp-devops-leonteq-terraform"
  service = "storage-api.googleapis.com"

  disable_dependent_services = true

  provisioner "local-exec" {
       command = "sleep 60"
  }

}



resource "google_service_account" "iaccore-rp-t1-int0" {
  account_id = "iaccore-rp-t1-int0"

  display_name = "iaccore-rp-t1-int0"


provisioner "local-exec" {
  command = "sleep 10"
}
  depends_on = [google_project_iam_binding.project_owner, google_project.grb-gcp-devops-leonteq-terraform, google_project_service.compute-googleapis-com, google_project_service.oslogin-googleapis-com, google_project_service.logging-googleapis-com, google_project_service.monitoring-googleapis-com, google_project_service.iam-googleapis-com, google_project_service.bigquery-json-googleapis-com, google_project_service.sourcerepo-googleapis-com, google_project_service.cloudkms-googleapis-com, google_project_service.storage-api-googleapis-com, google_project_service.iamcredentials-googleapis-com, google_project_service.cloudresourcemanager-googleapis-com, google_project_service.datacatalog-googleapis-com, google_project_service.bigquerystorage-googleapis-com, google_project_service.pubsub-googleapis-com]

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




resource "google_storage_bucket" "grb-gcp-devops-leonteq-terraform-server-secrets" {

  name = "grb-gcp-devops-leonteq-terraform-server-secrets"
  location = "europe-west1"
  storage_class = "REGIONAL"
  labels = {
    region= "europe-west1"
    environment = "int0"
  }
  depends_on = [google_project.grb-gcp-devops-leonteq-terraform, google_project_service.compute-googleapis-com, google_project_service.oslogin-googleapis-com, google_project_service.logging-googleapis-com, google_project_service.monitoring-googleapis-com, google_project_service.iam-googleapis-com, google_project_service.bigquery-json-googleapis-com, google_project_service.sourcerepo-googleapis-com, google_project_service.cloudkms-googleapis-com, google_project_service.storage-api-googleapis-com, google_project_service.iamcredentials-googleapis-com, google_project_service.cloudresourcemanager-googleapis-com, google_project_service.datacatalog-googleapis-com, google_project_service.bigquerystorage-googleapis-com, google_project_service.pubsub-googleapis-com]

}

output "google_storage_bucket_grb-gcp-devops-leonteq-terraform-server-secrets_name" {
  value = google_storage_bucket.grb-gcp-devops-leonteq-terraform-server-secrets.name
}
output "google_storage_bucket_grb-gcp-devops-leonteq-terraform-server-secrets_self_link" {
  value = google_storage_bucket.grb-gcp-devops-leonteq-terraform-server-secrets.self_link
}
output "google_storage_bucket_grb-gcp-devops-leonteq-terraform-server-secrets_url" {
  value = google_storage_bucket.grb-gcp-devops-leonteq-terraform-server-secrets.url
}



resource "google_storage_bucket" "skyuk-uk-poc-iaccore-rp-t1-is-int0" {

  name = "skyuk-uk-poc-iaccore-rp-t1-is-int0"
  location = "europe-west1"
  storage_class = "REGIONAL"
  labels =
  {
    region= "europe-west1"
    environment = "int0"
    terraform = "true"
  }
  depends_on = [google_project.grb-gcp-devops-leonteq-terraform, google_project_service.compute-googleapis-com, google_project_service.oslogin-googleapis-com, google_project_service.logging-googleapis-com, google_project_service.monitoring-googleapis-com, google_project_service.iam-googleapis-com, google_project_service.bigquery-json-googleapis-com, google_project_service.sourcerepo-googleapis-com, google_project_service.cloudkms-googleapis-com, google_project_service.storage-api-googleapis-com, google_project_service.iamcredentials-googleapis-com, google_project_service.cloudresourcemanager-googleapis-com, google_project_service.datacatalog-googleapis-com, google_project_service.bigquerystorage-googleapis-com, google_project_service.pubsub-googleapis-com]

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




google_compute_subnetwork:
  - provider: google
    resource_types:
      - resource_type: compute_subnetwork
        resources:

          - name: "{{ CONTAINER_CLUSTER_SUBNETWORK_NAME }}"
            ip_cidr_range: "{{ CONTAINER_CLUSTER_SUBNETWORK_CIDR }}"
            network: "default"
            project: "{{ GOOGLE_PROJECT_NAME }}"
            description: "Kubernetes Container Cluster Subnetwork for Pods and Services"
            enable_flow_logs: "false"
            private_ip_google_access: "false"
            secondary_ip_range:
              - range_name: "{{ CONTAINER_CLUSTER_PODS_SECONDARY_RANGE_NAME }}"
                ip_cidr_range: "{{ CONTAINER_CLUSTER_PODS_SECONDARY_RANGE_CIDR }}"
              - range_name: "{{ CONTAINER_CLUSTER_SERVICES_SECONDARY_RANGE_NAME }}"
                ip_cidr_range: "{{ CONTAINER_CLUSTER_SERVICES_SECONDARY_RANGE_CIDR }}"



google_container_cluster:
  - provider: google
    resource_types:
      - resource_type: container_cluster
        resources:

          - name: "{{ CONTAINER_CLUSTER_NAME }}"
            network: "default"
            subnetwork: "{{ CONTAINER_CLUSTER_SUBNETWORK_NAME }}"
            ip_allocation_policy:
              cluster_secondary_range_name: "{{ CONTAINER_CLUSTER_PODS_SECONDARY_RANGE_NAME }}"
              cluster_ipv4_cidr_block: "{{ CONTAINER_CLUSTER_PODS_SECONDARY_RANGE_CIDR }}"
              services_secondary_range_name: "{{ CONTAINER_CLUSTER_SERVICES_SECONDARY_RANGE_NAME }}"
              services_ipv4_cidr_block: "{{ CONTAINER_CLUSTER_SERVICES_SECONDARY_RANGE_CIDR }}"
              create_subnetwork: false
            zone: "{{ google_zone_b }}"
            maintenance_policy:
              daily_maintenance_window:
                start_time: "01:00"
            master_auth:
              # Leave username and password to disable Basic Authentication
              username: ""
              password: ""
              # Cient Certificate is considered a Legacy Authorisation method
              # Disable to avoid errors like: User \"client\" cannot create namespaces/secrets ...
              client_certificate_config:
                issue_client_certificate: false
            node_pools:
              - name: "default"
                initial_node_count: "{{ container_cluster_primary_initial_node_count | default('1') }}"
                node_config:
                  disk_size_gb: "{{ container_cluster_disk_size_gb | default('10') }}"
                  machine_type: "{{ container_cluster_machine_type | default('n1-standard-2') }}"
                  oauth_scopes:
                    - "https://www.googleapis.com/auth/compute"
                    - "https://www.googleapis.com/auth/devstorage.read_only"
                    - "https://www.googleapis.com/auth/logging.write"
                    - "https://www.googleapis.com/auth/monitoring"
                autoscaling:
                   max_node_count: "{{ container_cluster_max_node_count | default('3') }}"
                   min_node_count: "{{ container_cluster_min_node_count | default('1') }}"
                management:
                  auto_upgrade: "true"
                  auto_repair: "true"
            outputs:
              - "master_auth.0.client_certificate"
              - "master_auth.0.client_key"
              - "master_auth.0.cluster_ca_certificate"
              - "endpoint"
              - "name"
              - "master_version"
            depends_on:
              - "google_compute_subnetwork.{{ CONTAINER_CLUSTER_SUBNETWORK_NAME }}"



google_compute_ssl_certificate:
  - provider: google
    resource_types:
    - resource_type: compute_ssl_certificate
      resources:
        - name: "{{ EXTERNAL_SSL_CERTIFICATE_RESOURCE_NAME }}"
          certificate: "${file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PUBLIC_KEY_FILENAME }}\") }" # Retrieved in terraform_build.yml
          private_key: "${file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PRIVATE_KEY_FILENAME }}\") }" # Retrieved in terraform_build.yml
