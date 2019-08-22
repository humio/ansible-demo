resource "google_compute_instance_group" "humioingest_a" {
  name        = "humio-ingest-a"
  description = "humio-ingest-a"

  instances = [
                "${google_compute_instance_from_template.humio10.self_link}"
              ]

  named_port {
    name = "es"
    port = "9200"
  }
}

resource "google_compute_instance_group" "humioingest_b" {
  name        = "humio-ingest-b"
  description = "humio-ingest-b"

  instances = [
                "${google_compute_instance_from_template.humio11.self_link}"
              ]

  named_port {
    name = "es"
    port = "9200"
  }

  zone = "${var.region}-b"
}
resource "google_compute_instance_group" "humioingest_c" {
  name        = "humio-ingest-c"
  description = "humio-ingest-c"

  instances = [
                "${google_compute_instance_from_template.humio12.self_link}"
              ]

  named_port {
    name = "es"
    port = "9200"
  }

  zone = "${var.region}-c"
}