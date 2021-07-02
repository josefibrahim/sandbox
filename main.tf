provider "google" {
  version = "3.44.0"

  project = var.project
  region  = var.region
  zone    = var.zone
}