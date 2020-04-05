#########################################################
#
# Container Cluster
#
#########################################################

resource "google_container_cluster" "container-cluster" {

  project = local.project-name
  location = var.zone
  name = var.container-cluster-name
  network = "default"
  subnetwork = var.container-cluster-subnetwork-name

  remove_default_node_pool = true
  initial_node_count = 1

  ip_allocation_policy {
   cluster_secondary_range_name = var.container-cluster-pods-secondary-range-name
   services_secondary_range_name = var.container-cluster-services-secondary-range-name
  }

  maintenance_policy {
   daily_maintenance_window {
     start_time = "01:00"
   }
  }

  master_auth {
   # Leave username and password blank to disable Basic Authentication
   username = ""
   password = ""
   # Cient Certificate is considered a Legacy Authorisation method
   # Disable to avoid errors like: User \"client\" cannot create namespaces/secrets ...
   client_certificate_config {
     issue_client_certificate = "false"
   }
  }

  depends_on = [ google_project.current-project, google_project_service.container-googleapis-com, google_compute_subnetwork.k8s-subnetwork]

}



resource "google_container_node_pool" "primary_preemptible_nodes" {
  name = "default"
  project = local.project-name
  cluster = google_container_cluster.container-cluster.name
  initial_node_count = var.cluster-initial-node-count


  node_config {
    preemptible = true
    metadata = {
        disable-legacy-endpoints = "true"
      }
    disk_size_gb = var.cluster-node-disk-size-gb
    machine_type = var.cluster-node-machine-type
    service_account = google_service_account.project-service-account.email
    oauth_scopes = [ "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring" ]
  }

  autoscaling {
     max_node_count = var.cluster-max-node-count
     min_node_count = var.cluster-min-node-count
  }

  management {
    auto_upgrade = "true"
    auto_repair = "true"
  }

  depends_on = [ google_project.current-project, google_project_service.container-googleapis-com, google_compute_subnetwork.k8s-subnetwork]
}
