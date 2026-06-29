locals {
  # Core APIs the lab needs across all increments. Enabled once here so later
  # increments don't have to keep toggling services on.
  gcp_apis = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "oslogin.googleapis.com",
    "secretmanager.googleapis.com",
    "iap.googleapis.com",
    "storage.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.gcp_apis)

  project = var.project_id
  service = each.value

  # Keep APIs on when we tear down lab resources — avoids slow re-enable churn
  # on the next `apply`, and prevents disabling services other things may use.
  disable_dependent_services = false
  disable_on_destroy         = false
}
