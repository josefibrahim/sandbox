# forwarding rule -> proxy 
resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.name}-https-forwarding-rule"
  project    = var.project
  target     = google_compute_target_https_proxy.https-proxy.self_link
  ip_address = google_compute_global_address.default.address
  port_range = "443"
}

resource "google_compute_global_forwarding_rule" "http" {
  name       = "${var.name}-http-forwarding-rule"
  project    = var.project
  target     = google_compute_target_http_proxy.http-proxy.self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"
}


# proxy -> url map 
resource "google_compute_target_https_proxy" "https-proxy" {
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_target_http_proxy" "http-proxy" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.http-redirect.self_link
}

resource "google_compute_url_map" "http-redirect" {
  project = var.project
  name    = "${var.name}-http-redirect"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
    https_redirect         = true
  }
}

# url map -> backendServices
resource "google_compute_url_map" "url_map" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.backend.self_link
}


#certificate
resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  project  = var.project
  name     = "${var.name}-ssl-certificate"
  managed {
    domains = ["sandbox.josef.rack.gold"]
  }
}