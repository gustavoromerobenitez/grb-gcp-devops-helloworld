#########################################################
#
# Global Address
#
#########################################################
resource "google_compute_global_address" "global-address" {
  project = local.project-name
  name = "${var.environment}-global-address"
  description = "External IP address for the ${var.environment} environment Global HTTPS load balancer"
  address_type = "EXTERNAL"
  depends_on = [ google_project.current-project, google_project_service.compute-googleapis-com ]
}
