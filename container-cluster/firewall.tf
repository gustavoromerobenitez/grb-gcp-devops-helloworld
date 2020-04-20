google_compute_firewall "K8s_proxy_vm_ssh_access" {
  network = "default"
  allow {
    protocol = "tcp"
    ports = [ "22" ]
  }

  target_tags = [ "proxy-vm"]
}
