resource "google_compute_global_address" "default" {
  name = "humio-global-ip"
}

resource "google_compute_global_forwarding_rule" "https" {
  name       = "humio-global-forward"
  target     = "${google_compute_target_https_proxy.default.self_link}"
  ip_address = "${google_compute_global_address.default.address}"
  port_range = "443"
}

resource "google_compute_http_health_check" "default" {
  name               = "default"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
  port = 8080
}

resource "google_compute_target_https_proxy" "default" {
  name             = "humio-https-proxy"
  url_map          = "${google_compute_url_map.default.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.default.self_link}"]
}

resource "google_compute_ssl_certificate" "default" {
  name        = "humio-certificate"
  private_key = "${file(var.https_private_key)}"
  certificate = "${file(var.https_certificate)}"
}

resource "google_compute_url_map" "default" {
  name        = "humio-url-map"
  description = "https map"

  default_service = "${google_compute_backend_service.humio.self_link}"

  host_rule {
    hosts        = ["${var.https_hostname}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.humio.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.humio.self_link}"
    }
  }
}

resource "google_compute_backend_service" "humio" {
  name        = "humio-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  # backend {
  #   group = "${google_compute_instance_group.humionodes.self_link}"
  # }

  # backend {
  #   group = "${google_compute_instance_group.humionodes_b.self_link}"
  # }

  # backend {
  #   group = "${google_compute_instance_group.humionodes_c.self_link}"
  # }

  health_checks = ["${google_compute_http_health_check.default.self_link}"]
}
