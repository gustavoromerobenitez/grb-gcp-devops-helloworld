data "google_compute_image" "debian_image" {
  family  = "debian-9"
  project = "debian-cloud"
}


resource "google_compute_instance" "k8s_proxy_vm" {
  name         = "k8s-proxy-vm"
  machine_type = "n1-standard-1"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
      type = "pd-standard"
      size = "5GB"
    }
  }

  # Used to determine which firewall rules apply
  tags = [ "proxy-vm"]

  network_interface {
    subnetwork = google_compute_subnetwork.k8s-subnetwork.self_link
    network_ip = google_compute_address.k8s_proxy_vm_private_ip.self_link
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enabled_secure_boot = true
    enable_vtpm = true
    enable_integrity_monitoring = true
  }
}