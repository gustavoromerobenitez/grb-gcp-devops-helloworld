#########################################################
#
# Network
#
#########################################################
resource "google_compute_subnetwork" "k8s-subnetwork" {

    name = var.container-cluster-subnetwork-name
    ip_cidr_range = var.container-cluster-cidr-range
    network = "default"
    project = local.project-name
    description = "Kubernetes Container Cluster Subnetwork for Pods and Services"
    private_ip_google_access = "false"
    secondary_ip_range = [
      {
        range_name = var.container-cluster-pods-secondary-range-name
        ip_cidr_range = var.container-cluster-pods-secondary-range-cidr
      },
      {
        range_name = var.container-cluster-services-secondary-range-name
        ip_cidr_range = var.container-cluster-services-secondary-range-cidr
      }
    ]

    depends_on = [ google_project.current-project, google_project_service.compute-googleapis-com ]
}
