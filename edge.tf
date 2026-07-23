variable "edge_machine_type" {
  description = "Machine type for the edge router / NVA."
  type        = string
  default     = "e2-small"
}

resource "google_service_account" "edge" {
  account_id   = "${var.name_prefix}-edge"
  display_name = "SOC lab edge router / NVA"
}

resource "google_compute_instance" "edge" {
  name           = "${var.name_prefix}-edge"
  machine_type   = var.edge_machine_type
  zone           = var.zone
  can_ip_forward = true # required to route/forward other hosts' traffic
  tags           = ["edge-nva"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link # Ubuntu 24.04
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["edge"].id
    access_config {} # ephemeral public IP — the WAN / published edge
  }

  service_account {
    email  = google_service_account.edge.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/scripts/edge-router.sh.tftpl", {
    targets_cidr = local.subnets["targets"].cidr
  })

  depends_on = [google_compute_router_nat.nat]
}

# Send DVWA's internet-bound traffic through the edge router instead of Cloud
# NAT. Tag-scoped to "via-edge" so only DVWA uses it; the edge box itself is
# untagged and keeps the default route (no loop). Priority < 1000 so it wins.
resource "google_compute_route" "via_edge" {
  name              = "${var.name_prefix}-via-edge"
  network           = google_compute_network.vpc.id
  dest_range        = "0.0.0.0/0"
  next_hop_instance = google_compute_instance.edge.self_link
  priority          = 900
  tags              = ["via-edge"]
}

output "edge_public_ip" {
  description = "Public IP of the edge router (the future published entry point)."
  value       = google_compute_instance.edge.network_interface[0].access_config[0].nat_ip
}

output "edge_internal_ip" {
  description = "Internal IP of the edge router."
  value       = google_compute_instance.edge.network_interface[0].network_ip
}
