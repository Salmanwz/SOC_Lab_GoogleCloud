resource "google_service_account" "dvwa" {
  account_id   = "${var.name_prefix}-dvwa"
  display_name = "SOC lab DVWA web target"
}

resource "google_compute_instance" "dvwa" {
  name         = "${var.name_prefix}-dvwa"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link # Ubuntu 24.04
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["targets"].id
    # No public IP. Deliberately vulnerable — only reachable over the tailnet.
  }

  service_account {
    email  = google_service_account.dvwa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  # Referencing the manager's IP creates an implicit dependency, so the SOC
  # server is built first and its address is baked into the agent config.
  metadata_startup_script = templatefile("${path.module}/scripts/dvwa-agent.sh.tftpl", {
    manager_ip    = google_compute_instance.soc_server.network_interface[0].network_ip
    wazuh_version = var.wazuh_version
  })

  depends_on = [google_compute_router_nat.nat]
}

output "dvwa_internal_ip" {
  description = "Private IP of the DVWA target (browse http://<ip> over the tailnet)."
  value       = google_compute_instance.dvwa.network_interface[0].network_ip
}
