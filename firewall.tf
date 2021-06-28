 # to allow only traffic from the load balancer and health checker
 resource "google_compute_firewall" "lb" {
     name = "${var.name}-lb"
     network = google_compute_network.vpc_network.name
     source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

     allow {
         protocol   = "tcp"
         ports       = ["443"]
     }
     target_tags = ["lb"]
 }

 # to allow sshing
 resource "google_compute_firewall" "ssh" {
     name           = "${var.name}-ssh"
     network        = google_compute_network.vpc_network.name
     source_ranges  = ["0.0.0.0/0"]

     allow{
         protocol   = "tcp"
         ports       = ["22"]
     }

     target_tags = ["ssh"]
 }