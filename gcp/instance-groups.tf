resource "google_compute_instance_group" "humionodes_a" {
  name        = "humio-nodes-a"
  description = "humio-nodes-a"

  instances = [
                "${google_compute_instance_from_template.humio01.self_link}",
                "${google_compute_instance_from_template.humio04.self_link}",
                "${google_compute_instance_from_template.humio07.self_link}"
              ]

  named_port {
    name = "http"
    port = "8081"
  }

  named_port {
    name = "es"
    port = "9201"
  }

  named_port {
    name = "https"
    port = "443"
  }

  zone = "${var.region}-a"
}

resource "google_compute_instance_group" "humionodes_b" {
  name        = "humio-nodes-b"
  description = "humio-nodes-b"

  instances = [
                "${google_compute_instance_from_template.humio02.self_link}",
                "${google_compute_instance_from_template.humio05.self_link}",
                "${google_compute_instance_from_template.humio08.self_link}"
              ]

  named_port {
    name = "http"
    port = "8081"
  }

  named_port {
    name = "es"
    port = "9201"
  }

  named_port {
    name = "https"
    port = "443"
  }

  zone = "${var.region}-b"
}
resource "google_compute_instance_group" "humionodes_c" {
  name        = "humio-nodes-c"
  description = "humio-nodes-c"

  instances = [
                "${google_compute_instance_from_template.humio03.self_link}",
                "${google_compute_instance_from_template.humio06.self_link}",
                "${google_compute_instance_from_template.humio09.self_link}"
              ]

  named_port {
    name = "http"
    port = "8081"
  }

  named_port {
    name = "es"
    port = "9201"
  }

  named_port {
    name = "https"
    port = "443"
  }

  zone = "${var.region}-c"
}