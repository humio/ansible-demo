resource "google_compute_firewall" "local-network" {
  name    = "${google_compute_network.vpc_network.name}-local-network"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "tcp"
    ports    = ["2181","2888", "3888","8080","9092", "9200"]
  }

  allow {
    protocol = "udp"
    ports    = ["2888","3888"]
  }
  allow {
    protocol = "icmp"
  }

  target_tags   = ["humios", "humioingest", "kafkas", "zookeepers"]
  source_tags   = ["humios", "humioingest", "kafkas", "zookeepers"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "${google_compute_network.vpc_network.name}-health-check"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "tcp"
    ports    = ["8081"]
  }

  target_tags   = ["humios"]
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

resource "google_compute_firewall" "external" {
  name    = "${google_compute_network.vpc_network.name}-external"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "9200"]
  }

  target_tags   = ["humios", "humioingest", "kafkas"]
  source_ranges = "${var.external_access_ips}"
}
