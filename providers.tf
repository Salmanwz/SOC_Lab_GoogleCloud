provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone

  # Applied automatically to every labelable resource we create.
  default_labels = var.labels
}
