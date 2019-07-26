
resource "google_compute_global_address" "default" {
  name = "humio-global-ip"
}
# resource "google_compute_global_address" "es" {
#   name = "humio-global-es-ip"
# }
resource "google_compute_global_forwarding_rule" "https" {
  name       = "humio-global-forward-${local.dependency_id}"
  target     = "${google_compute_target_https_proxy.default.self_link}"
  ip_address = "${google_compute_global_address.default.address}"
  port_range = "443"
}
# resource "google_compute_global_forwarding_rule" "es" {
#   name       = "humio-global-forward-es"
#   target     = "${google_compute_target_https_proxy.es.self_link}"
#   ip_address = "${google_compute_global_address.es.address}"
#   port_range = "443"
# }


resource "google_compute_http_health_check" "default" {
  name               = "default"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
  port = 8080
}
# resource "google_compute_health_check" "es" {
#   name               = "escheck"
#   check_interval_sec = 1
#   timeout_sec        = 1
#   tcp_health_check {
#     port = "9200"
#   }
# }
resource "google_compute_target_https_proxy" "default" {
  name             = "humio-https-proxy-${local.dependency_id}"
  url_map          = "${google_compute_url_map.default.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.default.self_link}"]
}

# resource "google_compute_target_https_proxy" "es" {
#   name             = "humio-es-proxy"
#   ssl_certificates = ["${google_compute_ssl_certificate.es.self_link}"]
#   url_map          = "${google_compute_url_map.es.self_link}"
# }

resource "google_compute_ssl_certificate" "default" {
  name        = "humio-certificate"
  private_key = "${file(var.https_private_key)}"
  certificate = "${file(var.https_certificate)}"
}
# resource "google_compute_ssl_certificate" "es" {
#   name        = "humio-es-certificate"
#   private_key = "${file(var.es_private_key)}"
#   certificate = "${file(var.es_certificate)}"
# }

resource "google_compute_url_map" "default" {
  name        = "humio-url-map-${local.dependency_id}"
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
# resource "google_compute_url_map" "es" {
#   name        = "humio-es-url-map"
#   description = "https map for es"

#   default_service = "${google_compute_backend_service.humioes.self_link}"

#   host_rule {
#     hosts        = ["${var.es_hostname}"]
#     path_matcher = "allpaths"
#   }

#   path_matcher {
#     name            = "allpaths"
#     default_service = "${google_compute_backend_service.humioes.self_link}"

#     path_rule {
#       paths   = ["/*"]
#       service = "${google_compute_backend_service.humioes.self_link}"
#     }
#   }
# }


resource "google_compute_backend_service" "humio" {
  name        = "humio-backend-service-${local.dependency_id}"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  # backend = {"${element(google_compute_instance.humios.*.self_link, count.index)}"}
  backend {
    group = "${google_compute_instance_group.humionodes.0.self_link}"
  }
  backend {
    group = "${google_compute_instance_group.humionodes.1.self_link}"
  }
  backend {
    group = "${google_compute_instance_group.humionodes.2.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.default.self_link}"]
}

# resource "google_compute_backend_service" "humioes" {
#   name        = "humio-backend-service-es"
#   port_name   = "es"
#   protocol    = "HTTP"
#   timeout_sec = 10

#   backend {
#     group = "${google_compute_instance_group.humionodes.self_link}"
#   }

#   health_checks = ["${google_compute_health_check.es.self_link}"]
# }
