resource "google_dns_managed_zone" "parent-zone" {
  provider = "google-beta"
  project  = var.project
  name     = "${var.name}-zone"
  dns_name = "josef.rack.gold."
}

resource "google_dns_record_set" "recordset" {
  managed_zone = google_dns_managed_zone.parent-zone.name
  name         = "sandbox.josef.rack.gold."
  type         = "A"
  rrdatas      = [google_compute_global_address.default.address]
  ttl          = 60
}