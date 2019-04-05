// Configure the Google Cloud provider
provider "google" {
 credentials = "${file(var.gcp_credentials)}"
 project     = "${var.gcp_project_id}"
 region      = "${var.region}"
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.vpc_network_name}"
  auto_create_subnetworks = "false"
  ipv4_range = "${var.vpc_network_cidr}"
}

resource "google_compute_firewall" "local-network" {
  name    = "${google_compute_network.vpc_network.name}-local-network"
  network = "${google_compute_network.vpc_network.name}"

 allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["${var.vpc_network_cidr}"]
}
resource "google_compute_firewall" "external" {
  name    = "${google_compute_network.vpc_network.name}-external"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "9200"]
  }

  target_tags   = ["humios", "kafkas"]
  source_ranges = "${var.external_access_ips}"
}
resource "google_compute_firewall" "allow_health_check" {
  name    = "${google_compute_network.vpc_network.name}-health-check"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "tcp"
    ports    = ["8080", "9200"]
  }

  target_tags   = ["humios", "kafkas"]
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}


resource "google_compute_global_address" "default" {
  name = "humio-global-ip"
}
resource "google_compute_global_address" "es" {
  name = "humio-global-es-ip"
}
resource "google_compute_global_forwarding_rule" "https" {
  name       = "humio-global-forward"
  target     = "${google_compute_target_https_proxy.default.self_link}"
  ip_address = "${google_compute_global_address.default.address}"
  port_range = "443"
}
resource "google_compute_global_forwarding_rule" "es" {
  name       = "humio-global-forward-es"
  target     = "${google_compute_target_https_proxy.es.self_link}"
  ip_address = "${google_compute_global_address.es.address}"
  port_range = "443"
}


resource "google_compute_http_health_check" "default" {
  name               = "default"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
  port = 8080
}
resource "google_compute_health_check" "es" {
  name               = "escheck"
  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port = "9200"
  }
}


// create an pd-ssd for each humio-host
resource "google_compute_disk" "humio-pd-ssd-" {
    count   = "${var.instances}"
    name    = "humio-pd-ssd-${count.index}-data"
    type    = "pd-ssd"
    zone    = "${var.zone}"
    size    = "${var.humio_disk_size}"
}

resource "google_compute_instance" "humios" {
 count = "${var.instances}"
 name = "${format("humio%02d-%s", count.index + 1, var.region)}"
 machine_type = "${var.machine_type}" 
 zone         = "${var.zone}"

 attached_disk {
    source      = "${element(google_compute_disk.humio-pd-ssd-.*.self_link, count.index)}"
    device_name = "${element(google_compute_disk.humio-pd-ssd-.*.name, count.index)}"
 }

 boot_disk {
   initialize_params {
     image = "${var.boot_disk_image}" 
     size = "${var.boot_disk_size}"
   } 
 }

 metadata {
   sshKeys = "${var.ansible_ssh_user}:${var.access_pub_key}"
 }

 tags = [
        "${count.index < var.zookeepers ? "zookeepers" : "no-zookeepers"}",
        "kafkas",
        "humios"
  ]


 metadata_startup_script = <<SCRIPT
 sudo apt-get update
 sudo apt-get install -yq build-essential python
 sudo mkdir -p /etc/ansible/facts.d/ 
 sudo echo ${count.index + 1} > /etc/ansible/facts.d/cluster_index.fact
 SCRIPT
 network_interface {
   network = "${google_compute_network.vpc_network.name}"

   access_config {
     // Include this section to give the VM an external ip address
   }
 }
}
resource "google_compute_instance_group" "humionodes" {
  name        = "humio-nodes"
  description = "humio-nodes"

  instances = ["${google_compute_instance.humios.*.self_link}"]

  named_port {
    name = "http"
    port = "8080"
  }

  named_port {
    name = "es"
    port = "9200"
  }

  zone = "${var.zone}"
} 

resource "google_compute_target_https_proxy" "default" {
  name             = "humio-https-proxy"
  url_map          = "${google_compute_url_map.default.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.default.self_link}"]
}

resource "google_compute_target_https_proxy" "es" {
  name             = "humio-es-proxy"
  ssl_certificates = ["${google_compute_ssl_certificate.es.self_link}"]
  url_map          = "${google_compute_url_map.es.self_link}"
}

resource "google_compute_ssl_certificate" "default" {
  name        = "humio-certificate"
  private_key = "${file(var.https_private_key)}"
  certificate = "${file(var.https_certificate)}"
}
resource "google_compute_ssl_certificate" "es" {
  name        = "humio-es-certificate"
  private_key = "${file(var.es_private_key)}"
  certificate = "${file(var.es_certificate)}"
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
resource "google_compute_url_map" "es" {
  name        = "humio-es-url-map"
  description = "https map for es"

  default_service = "${google_compute_backend_service.humioes.self_link}"

  host_rule {
    hosts        = ["${var.es_hostname}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.humioes.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.humioes.self_link}"
    }
  }
}


resource "google_compute_backend_service" "humio" {
  name        = "humio-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.humionodes.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.default.self_link}"]
}

resource "google_compute_backend_service" "humioes" {
  name        = "humio-backend-service-es"
  port_name   = "es"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.humionodes.self_link}"
  }

  health_checks = ["${google_compute_health_check.es.self_link}"]
}


