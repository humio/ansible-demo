resource "google_compute_instance_group" "humionodes_a" {
  name        = "humio-nodes-a"
  description = "humio-nodes-a"

  instances = [
                "${google_compute_instance.humio01.self_link}",
                "${google_compute_instance.humio04.self_link}",
                "${google_compute_instance.humio07.self_link}"
              ]

  named_port {
    name = "https"
    port = "443"
  }

  named_port {
    name = "http"
    port = "8081"
  }

  named_port {
    name = "es"
    port = "9092"
  }


  zone = "${var.region}-a"
}

resource "google_compute_instance_group" "humionodes_b" {
  name        = "humio-nodes-b"
  description = "humio-nodes-b"

  instances = [
                "${google_compute_instance.humio02.self_link}",
                "${google_compute_instance.humio05.self_link}",
                "${google_compute_instance.humio08.self_link}"
              ]


  named_port {
    name = "https"
    port = "443"
  }

  named_port {
    name = "http"
    port = "8081"
  }

  named_port {
    name = "es"
    port = "9092"
  }

  zone = "${var.region}-b"
}
resource "google_compute_instance_group" "humionodes_c" {
  name        = "humio-nodes-c"
  description = "humio-nodes-c"

  instances = [
                "${google_compute_instance.humio03.self_link}",
                "${google_compute_instance.humio06.self_link}",
                "${google_compute_instance.humio09.self_link}"
              ]


  named_port {
    name = "https"
    port = "443"
  }

  named_port {
    name = "http"
    port = "8081"
  }

  named_port {
    name = "es"
    port = "9092"
  }

  zone = "${var.region}-c"
}