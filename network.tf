resource "google_compute_network" "vpc_network"{
    name = "${var.name}-network"
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 0.4"
  project = var.project
  name    = "${var.name}-router"
  network = google_compute_network.vpc_network.name
  region  = var.region

  nats = [{
    name = "${var.name}-gateway"
  }]
}