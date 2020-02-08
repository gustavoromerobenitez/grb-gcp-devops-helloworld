provider "google" {
  version = "${var.google-provider-version}"
  project = "${var.project-name}"
  region  = "${var.region}"
}

#provider "kubernetes" {
#
#  host = "${data.terraform_remote_state.${var.project-name}.google_container_cluster_${var.container-cluster-name}_endpoint}"
#  insecure = "false"
#  client_certificate = "${base64decode(data.terraform_remote_state.${var.project-name}.google_container_cluster_${var.container-cluster-name}_master_auth_0_client_certificate)}"
#  client_key = "${base64decode(data.terraform_remote_state.${var.project-name}.google_container_cluster_${var.container-cluster-name}_master_auth_0_client_key)}"
#  cluster_ca_certificate = "${base64decode(data.terraform_remote_state.${var.project-name}.google_container_cluster_${var.container-cluster-name}_master_auth_0_cluster_ca_certificate)}"
#
#}


data "terraform_remote_state" "${var.project-name}" {
  backend = "gcs"
  config = {
    bucket = "${var.remote-state-bucket}"
    prefix = "${var.remote-state-prefix}"
  }
}


resource "google_project" "${var.project-name}" {

  name = "${var.project-name}"
  project_id = "${var.project-name}"
  billing_account = "${var.billing-account}"
  skip_delete = "true"

  labels = {
    environment = "${var.environment}"
    terraform = "true"
  }

  provisioner "local-exec" { command = "sleep 60"  }
}


resource "google_project_iam_binding" "project_owner" {
  project = "${var.project-name}"
  role = "roles/owner"
  members = [ "serviceAccount:${var.project-service-account-name}@${var.project-name}.iam.gserviceaccount.com" ]
  provisioner "local-exec" { command = "sleep 10" }
  depends_on = [ "google_project.${var.project-name}", google_project_service.compute-googleapis-com, google_project_service.iam-googleapis-com]
}



#resource "google_project_iam_custom_role" "BigQueryRO" {
#  role_id = "BigQueryRO"
#  title = "BigQuery RO"
#  permissions = [ "bigquery.datasets.get", "bigquery.datasets.getIamPolicy", "bigquery.tables.get", "bigquery.tables.getData", "bigquery.tables.list", "resourcemanager.projects.get" ]
#
#  description = "BigQuery Data Viewer role without export"
#
#
#  provisioner "local-exec" {
#    command = "sleep 10"
#  }
#
#  depends_on = [google_project.${var.project-name}, google_project_service.compute-googleapis-com, google_project_service.oslogin-googleapis-com, google_project_service.logging-googleapis-com, google_project_service.monitoring-googleapis-com, google_project_service.iam-googleapis-com, google_project_service.bigquery-json-googleapis-com, google_project_service.sourcerepo-googleapis-com, google_project_service.cloudkms-googleapis-com, google_project_service.storage-api-googleapis-com, #google_project_service.iamcredentials-googleapis-com, google_project_service.cloudresourcemanager-googleapis-com, google_project_service.datacatalog-googleapis-com, google_project_service.bigquerystorage-googleapis-com, google_project_service.pubsub-googleapis-com]
#}



resource "google_project_service" "iam-googleapis-com" {
  project = "${var.project-name}"
  service = "iam.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ "google_project.${var.project-name}" ]
}


resource "google_project_service" "storage-api-googleapis-com" {
  project = "${var.project-name}"
  service = "storage-api.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ "google_project.${var.project-name}" ]
}

resource "google_project_service" "container-googleapis-com" {
  project = "${var.project-name}"
  service = "container.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ "google_project.${var.project-name}" ]
}

resource "google_project_service" "containerregistry-googleapis-com" {
  project = "${var.project-name}"
  service = "containerregistry.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ "google_project.${var.project-name}" ]
}

resource "google_project_service" "compute-googleapis-com" {
  project = "${var.project-name}"
  service = "compute.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
  depends_on = [ "google_project.${var.project-name}" ]
}


resource "google_service_account" "${var.project-service-account-name}" {
  account_id = "${var.project-service-account-name}"
  display_name = "${var.project-service-account-name}"
  provisioner "local-exec" {  command = "sleep 10" }
  depends_on = [ google_project_iam_binding.project_owner, "google_project.${var.project-name}" ]
}





resource "google_storage_bucket" "${var.project-name}-bucket" {

  name = "${var.project-name}-bucket"
  location = "${var.region}"
  storage_class = "REGIONAL"
  labels = {
    region= "${var.region}"
    environment = "${var.environment}"
    terraform = "true"
  }
  depends_on = [ "google_project.${var.project-name}", google_project_service.iam-googleapis-com, google_project_service.storage-api-googleapis-com]
}



resource "google_compute_subnetwork" "${var.project-name}-compute-subnetwork" {

    ip_cidr_range = "${var.container-cluster-cidr-range}"
    network = "default"
    project = "${var.project-name}"
    description = "Kubernetes Container Cluster Subnetwork for Pods and Services"
    enable_flow_logs = "false"
    private_ip_google_access = "false"
    secondary_ip_range = [
      {
        range_name = "${var.container-cluster-pods-secondary-range-name}"
        ip_cidr_range = "${var.container-cluster-pods-secondary-range-cidr}"
      },
      {
        range_name = "${var.container-cluster-services-secondary-range-name}"
        ip_cidr_range = "${var.container-cluster-services-secondary-range-cidr}"
      }
    ]

    depends_on = [ "google_project.${var.project-name}", google_project_service.compute-googleapis-com ]
}





resource "google_container_cluster" "${var.container-cluster-name}" {
   name = "${var.container-cluster-name}"

   network = "default"

   subnetwork = "${var.container-cluster-subnetwork-name}"

   ip_allocation_policy = {
     cluster_secondary_range_name = "${var.container-cluster-pods-secondary-range-name}"
     cluster_ipv4_cidr_block = "${var.container-cluster-pods-secondary-range-cidr}"
     services_secondary_range_name = "${var.container-cluster-services-secondary-range-name}"
     services_ipv4_cidr_block = "${var.container-cluster-services-secondary-range-cidr}"
     create_subnetwork = "false"
   }

   zone = "${var.zone}"

   maintenance_policy = {
     daily_maintenance_window = {
       start_time = "01:00"
     }
   }

   master_auth =  {
     # Leave username and password blank to disable Basic Authentication
     username = ""
     password = ""
     # Cient Certificate is considered a Legacy Authorisation method
     # Disable to avoid errors like: User \"client\" cannot create namespaces/secrets ...
     client_certificate_config = {
       issue_client_certificate = "false"
     }
   }

   node_pools = [
     {
       name = "default"
       initial_node_count = "${var.cluster-initial-node-count}"

       node_config = {
         disk_size_gb = "${var.cluster-node-disk-size-gb}"
         machine_type = "${var.cluster-node-machine-type}"
         oauth_scopes = [ "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring" ]
       }

       autoscaling = {
          max_node_count = "${var.cluster-max-node-count}"
          min_node_count = "${var.cluster-min-node-count}"
       }

       management = {
         auto_upgrade = "true"
         auto_repair = "true"
       }
     }# node pool
   ]

   outputs = [ "master_auth.0.client_certificate", "master_auth.0.client_key", "master_auth.0.cluster_ca_certificate", "endpoint", "name", "master_version" ]
   depends_on = [ "google_project.${var.project-name}", "google_compute_subnetwork.${var.container-cluster-subnetwork-name}"]
}
#
#
#
# resource "google_compute_ssl_certificate" "${var.ssl_certificate_name}" {
#     name = "{{ EXTERNAL_SSL_CERTIFICATE_RESOURCE_NAME }}"
#     certificate = "${file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PUBLIC_KEY_FILENAME }}\") }"
#     private_key = "${file(\"{{ EXTERNAL_SSL_CERTIFICATE_LOCAL_LOCATION }}/{{ EXTERNAL_SSL_CERTIFICATE_PRIVATE_KEY_FILENAME }}\") }"
# }
