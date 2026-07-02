# Increment 3 — throwaway VM to prove the subnet route forwards to a host that
# does NOT run Tailscale (like the real Wazuh/DVWA/Samba boxes will be).
# Set enable_testbox = false (or destroy) to remove it before building services.

variable "enable_testbox" {
  description = "Create the temporary reachability test box."
  type        = bool
  default     = true
}

resource "google_compute_instance" "testbox" {
  count = var.enable_testbox ? 1 : 0

  name         = "${var.name_prefix}-testbox"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["targets"].id
    # No public IP — reachable only via the tailnet subnet route (or IAP).
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  # Serve a tiny page so we can prove TCP reachability over the route.
  metadata_startup_script = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get -o DPkg::Lock::Timeout=180 update -y
    apt-get -o DPkg::Lock::Timeout=180 install -y nginx
    echo "soc-lab testbox — reached over the tailnet subnet route" >/var/www/html/index.html
    systemctl enable --now nginx
  EOT

  depends_on = [google_compute_router_nat.nat]
}

output "testbox_internal_ip" {
  description = "Private IP of the reachability test box."
  value       = var.enable_testbox ? google_compute_instance.testbox[0].network_interface[0].network_ip : null
}
