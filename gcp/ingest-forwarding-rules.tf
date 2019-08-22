

resource "google_compute_forwarding_rule" "es" {
  name       = "humio-es-internal"
  backend_service = "${google_compute_region_backend_service.humio_es.self_link}"
  network               = "${google_compute_network.default.name}"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  network = "${google_compute_network.vpc_network.name}"

}
resource "google_compute_health_check" "es" {
  name               = "es-check"
  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port = "9200"
  }
}

resource "google_compute_region_backend_service" "humio_es" {
  name        = "humio-backend-service-es"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.humioingest_a.self_link}"
  }

  backend {
    group = "${google_compute_instance_group.humioingest_b.self_link}"
  }

  backend {
    group = "${google_compute_instance_group.humioingest_c.self_link}"
  }

  health_checks = ["${google_compute_health_check.es.self_link}"]
}