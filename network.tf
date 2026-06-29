locals {
  # 10.10.0.0/16 carved into purpose-built /24s. Kept here (not a variable)
  # to stay readable while the lab is small; promote to a var if it grows.
  subnets = {
    soc     = { cidr = "10.10.10.0/24" } # SIEM / SOAR / case mgmt + tailscale router
    targets = { cidr = "10.10.20.0/24" } # DVWA, Samba AD DC, attacker box
    edge    = { cidr = "10.10.30.0/24" } # VyOS edge NVA (later increment)
  }
}

resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.enabled]
}

resource "google_compute_subnetwork" "subnet" {
  for_each = local.subnets

  name          = "${var.name_prefix}-${each.key}"
  ip_cidr_range = each.value.cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  # Lets private (no public IP) VMs reach *.googleapis.com — e.g. Secret
  # Manager, GCS — without NAT. Free. General internet egress comes later.
  private_ip_google_access = true
}

# East-west: allow all traffic between hosts inside the VPC.
resource "google_compute_firewall" "allow_internal" {
  name      = "${var.name_prefix}-allow-internal"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["10.10.0.0/16"]

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }
}

# Fallback admin access via IAP TCP forwarding (before/besides Tailscale).
# 35.235.240.0/20 is Google's fixed IAP source range.
resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "${var.name_prefix}-allow-iap-ssh"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

output "vpc_name" {
  description = "VPC network name."
  value       = google_compute_network.vpc.name
}

output "subnets" {
  description = "Subnet name -> CIDR."
  value       = { for k, s in google_compute_subnetwork.subnet : k => s.ip_cidr_range }
}
