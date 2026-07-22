variable "soc_server_machine_type" {
  description = "Machine type for the Wazuh SOC server. e2-standard-4 (16GB) is comfortable; e2-standard-2 (8GB) is the tighter, cheaper floor."
  type        = string
  default     = "e2-standard-4"
}

variable "wazuh_version" {
  description = "Wazuh major.minor to install (packages.wazuh.com/<ver>/). Bump to the latest supported release as needed."
  type        = string
  default     = "4.9"
}

# Ubuntu 22.04 for the Wazuh box — it's the release Wazuh 4.9 officially
# supports (24.04 isn't listed), so we pin it here rather than reuse 24.04.
data "google_compute_image" "ubuntu2204" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_service_account" "soc_server" {
  account_id   = "${var.name_prefix}-soc-server"
  display_name = "SOC lab Wazuh SIEM server"
}

resource "google_compute_instance" "soc_server" {
  name         = "${var.name_prefix}-soc-server"
  machine_type = var.soc_server_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu2204.self_link
      size  = 50
      type  = "pd-balanced" # better IOPS for the indexer than pd-standard
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["soc"].id
    # No public IP — dashboard reached over the tailnet subnet route.
    # Port 443 is already permitted by the allow-internal firewall rule.
  }

  service_account {
    email  = google_service_account.soc_server.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/scripts/wazuh-install.sh.tftpl", {
    wazuh_version = var.wazuh_version
  })

  allow_stopping_for_update = true

  depends_on = [google_compute_router_nat.nat]
}

output "soc_server_internal_ip" {
  description = "Private IP of the Wazuh SOC server (browse https://<ip> over the tailnet)."
  value       = google_compute_instance.soc_server.network_interface[0].network_ip
}
