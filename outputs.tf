output "project_id" {
  description = "Active GCP project."
  value       = var.project_id
}

output "enabled_apis" {
  description = "APIs enabled by this configuration."
  value       = sort([for s in google_project_service.enabled : s.service])
}
