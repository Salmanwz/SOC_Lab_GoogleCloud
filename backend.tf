terraform {
  backend "gcs" {
    bucket = "soc-lab-tfstate-v1"
    prefix = "soc-lab"
  }
}
