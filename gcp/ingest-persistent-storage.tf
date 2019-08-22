resource "google_compute_disk" "humio10-pd-ssd-a" {
  name  = "humio10-pd-ssd-a"
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  size  = "${var.humio_ingest_disk_size}"
}
resource "google_compute_disk" "humio11-pd-ssd-b" {
  name  = "humio11-pd-ssd-b"
  type  = "pd-ssd"
  zone  = "${var.region}-b"
  size  = "${var.humio_ingest_disk_size}"
}

resource "google_compute_disk" "humio12-pd-ssd-c" {
  name  = "humio12-pd-ssd-c"
  type  = "pd-ssd"
  zone  = "${var.region}-c"
  size  = "${var.humio_ingest_disk_size}"
}