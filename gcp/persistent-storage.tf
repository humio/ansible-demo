// create 2 pd-ssd for each humio-host
resource "google_compute_disk" "humio01-pd-ssd-a" {
  name  = "humio01-pd-ssd-a"
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  size  = "${var.humio_disk_size}"
}
resource "google_compute_disk" "humio01-kafka-pd-ssd-a" {
  name  = "humio01-kafka-pd-ssd-a"
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  size  = "${var.kafka_disk_size}"
}

resource "google_compute_disk" "humio01-zookeeper-pd-ssd-a" {
  name  = "humio01-zookeeper-pd-ssd-a"
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  size  = "${var.zookeeper_disk_size}"
}


resource "google_compute_disk" "humio02-pd-ssd-b" {
  name  = "humio02-pd-ssd-b"
  type  = "pd-ssd"
  zone  = "${var.region}-b"
  size  = "${var.humio_disk_size}"
}
resource "google_compute_disk" "humio02-kafka-pd-ssd-b" {
  name  = "humio02-kafka-pd-ssd-b"
  type  = "pd-ssd"
  zone  = "${var.region}-b"
  size  = "${var.kafka_disk_size}"
}

resource "google_compute_disk" "humio02-zookeeper-pd-ssd-b" {
  name  = "humio02-zookeeper-pd-ssd-b"
  type  = "pd-ssd"
  zone  = "${var.region}-b"
  size  = "${var.zookeeper_disk_size}"
}
resource "google_compute_disk" "humio03-pd-ssd-c" {
  name  = "humio03-pd-ssd-c"
  type  = "pd-ssd"
  zone  = "${var.region}-c"
  size  = "${var.humio_disk_size}"
}
resource "google_compute_disk" "humio03-kafka-pd-ssd-c" {
  name  = "humio03-kafka-pd-ssd-c"
  type  = "pd-ssd"
  zone  = "${var.region}-c"
  size  = "${var.kafka_disk_size}"
}

resource "google_compute_disk" "humio03-zookeeper-pd-ssd-c" {
  name  = "humio03-zookeeper-pd-ssd-c"
  type  = "pd-ssd"
  zone  = "${var.region}-c"
  size  = "${var.zookeeper_disk_size}"
}
resource "google_compute_disk" "humio04-pd-ssd-a" {
  name  = "humio04-pd-ssd-a"
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  size  = "${var.humio_disk_size}"
}
resource "google_compute_disk" "humio04-kafka-pd-ssd-a" {
  name  = "humio04-kafka-pd-ssd-a"
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  size  = "${var.kafka_disk_size}"
}

resource "google_compute_disk" "humio05-pd-ssd-b" {
  name  = "humio05-pd-ssd-b"
  type  = "pd-ssd"
  zone  = "${var.region}-b"
  size  = "${var.humio_disk_size}"
}
resource "google_compute_disk" "humio05-kafka-pd-ssd-b" {
  name  = "humio05-kafka-pd-ssd-b"
  type  = "pd-ssd"
  zone  = "${var.region}-b"
  size  = "${var.kafka_disk_size}"
}

resource "google_compute_disk" "humio06-pd-ssd-c" {
  name  = "humio06-pd-ssd-c"
  type  = "pd-ssd"
  zone  = "${var.region}-c"
  size  = "${var.humio_disk_size}"
}
resource "google_compute_disk" "humio06-kafka-pd-ssd-c" {
  name  = "humio06-kafka-pd-ssd-c"
  type  = "pd-ssd"
  zone  = "${var.region}-c"
  size  = "${var.kafka_disk_size}"
}

resource "google_compute_disk" "humio07-pd-ssd-a" {
  name  = "humio07-pd-ssd-a"
  type  = "pd-ssd"
  zone  = "${var.region}-a"
  size  = "${var.humio_disk_size}"
}
resource "google_compute_disk" "humio08-pd-ssd-b" {
  name  = "humio08-pd-ssd-b"
  type  = "pd-ssd"
  zone  = "${var.region}-b"
  size  = "${var.humio_disk_size}"
}

resource "google_compute_disk" "humio09-pd-ssd-c" {
  name  = "humio09-pd-ssd-c"
  type  = "pd-ssd"
  zone  = "${var.region}-c"
  size  = "${var.humio_disk_size}"
}

