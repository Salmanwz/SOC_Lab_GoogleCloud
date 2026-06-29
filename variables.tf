variable "project_id" {
  description = "GCP project id that hosts the SOC lab."
  type        = string
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Default GCP zone."
  type        = string
  default     = "us-central1-a"
}

variable "name_prefix" {
  description = "Prefix applied to resource names."
  type        = string
  default     = "soc-lab"
}

variable "labels" {
  description = "Labels applied to all resources (drives cost reporting)."
  type        = map(string)
  default     = { env = "lab" }
}
