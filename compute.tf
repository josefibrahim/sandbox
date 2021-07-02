resource "google_compute_instance" "vm" {
  name                      = "${var.name}-vm"
  machine_type              = "e2-medium"
  metadata_startup_script   = file("startup.sh")
  tags                      = ["lb", "ssh"]
  zone                      = var.zone
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    /*
         access_config{
             nat_ip = google_compute_address.static.address
         }
         */
  }

  service_account {
    scopes = ["cloud-platform"]
    email  = "wordpress@coen-josef-ibrahim.iam.gserviceaccount.com"
  }
}

resource "google_compute_instance_group" "instance_group" {
  name = "${var.name}-instance-group"
  zone = var.zone
  named_port {
    name = "https"
    port = "443"
  }
  network   = google_compute_network.vpc_network.id
  instances = [google_compute_instance.vm.self_link]
}

resource "google_compute_health_check" "https_health_check" {
  name = "${var.name}-health-check"

  timeout_sec         = 1
  check_interval_sec  = 5
  healthy_threshold   = 3
  unhealthy_threshold = 1

  https_health_check {
    port         = "443"
    request_path = "/hc"
  }
}

resource "google_compute_backend_service" "backend" {
  provider      = google-beta
  project       = var.project
  name          = "${var.name}-backend"
  health_checks = [google_compute_health_check.https_health_check.id]
  port_name     = "https"
  protocol      = "HTTPS"
  backend {
    group = google_compute_instance_group.instance_group.self_link
  }
}