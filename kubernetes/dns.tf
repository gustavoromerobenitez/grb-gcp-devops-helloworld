#########################################################
#
# DNS API
#
#########################################################

resource "google_project_service" "dns-googleapis-com" {
  project = local.project-name
  service = "dns.googleapis.com"
  disable_dependent_services = "true"
  provisioner "local-exec" { command = "sleep 60" }
}

#########################################################
#
# DNS Zone and A Record
#
#########################################################
resource "google_dns_managed_zone" "dns-zone" {
  project = local.project-name
  name = "grbdevops-net"
  dns_name = "grbdevops.net."
  description = "DNS zone"
  labels = {
    terraform = "true"
  }
  depends_on = [ google_project_service.dns-googleapis-com ]
}


resource "google_dns_record_set" "dns-a-record-set" {
  project = local.project-name
  name = google_dns_managed_zone.dns-zone.dns_name
  managed_zone = google_dns_managed_zone.dns-zone.name
  type = "A"
  ttl = "300"
  rrdatas = [ google_compute_global_address.global-address.address ]
  depends_on = [ google_project_service.dns-googleapis-com, google_dns_managed_zone.dns-zone, google_compute_global_address.global-address ]
}


resource "google_dns_record_set" "dns-cname-record-set" {
  project = local.project-name
  name = "leonteq-${var.environment}.${google_dns_managed_zone.dns-zone.dns_name}"
  managed_zone = google_dns_managed_zone.dns-zone.name
  type = "CNAME"
  ttl = "300"
  rrdatas = [ "leonteq-${var.environment}.${google_dns_managed_zone.dns-zone.dns_name}" ]
  depends_on = [ google_project_service.dns-googleapis-com, google_dns_managed_zone.dns-zone ]
}
