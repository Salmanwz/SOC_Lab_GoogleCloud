variable "ts_authkey" {
  description = "Tailscale auth key (tagged tag:soc-lab, reusable + ephemeral). Provide via TF_VAR_ts_authkey — never commit it."
  type        = string
  sensitive   = true
}

variable "ts_advertise_routes" {
  description = "CIDR(s) the subnet router advertises into the tailnet."
  type        = string
  default     = "10.10.0.0/16"
}

# Latest Ubuntu 24.04 LTS image.
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

# Dedicated, least-privilege identity for the router (no project roles bound).
resource "google_service_account" "ts_router" {
  account_id   = "${var.name_prefix}-ts-router"
  display_name = "SOC lab Tailscale subnet router"
}

# --- Egress for private VMs: Cloud Router + Cloud NAT ---
# Serves the whole VPC, so every no-public-IP VM in later increments reaches
# the internet through this. First billed resources in the lab (~$0.044/hr).
resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# --- The Tailscale subnet router VM (no public IP) ---
resource "google_compute_instance" "ts_router" {
  name           = "${var.name_prefix}-ts-router"
  machine_type   = "e2-small"
  zone           = var.zone
  can_ip_forward = true # required to forward subnet traffic
  tags           = ["tailscale-router"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet["soc"].id
    # No access_config block => no public IP. Egress via Cloud NAT.
  }

  service_account {
    email  = google_service_account.ts_router.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/scripts/tailscale-router.sh.tftpl", {
    ts_authkey       = var.ts_authkey
    advertise_routes = var.ts_advertise_routes
    hostname         = "${var.name_prefix}-ts-router"
  })

  depends_on = [google_compute_router_nat.nat]
}

output "ts_router_internal_ip" {
  description = "Private IP of the Tailscale subnet router."
  value       = google_compute_instance.ts_router.network_interface[0].network_ip
}
