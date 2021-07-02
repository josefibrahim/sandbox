resource "google_compute_network" "vpc_network" {
  name = "${var.name}-network"
}

resource "google_compute_router" "router" {
  name    = "wp-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "wp-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
/*
resource "google_compute_address" "static" {
  name = "ipv4-address"
  region = var.region
}
*/
resource "google_compute_global_address" "default" {
  name = "global-address"
}