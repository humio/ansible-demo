// Configure the Google Cloud provider
// this needs to move but whatever for noe
provider "google" {
 credentials = "${file("gcp_credentials.json")}"
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

// create an pd-ssd for each humio-host
resource "google_compute_disk" "humio-pd-ssd-" {
    count   = "${var.instances}"
    name    = "humio-pd-ssd-${count.index}-data"
    type    = "pd-ssd"
    zone    = "${var.zone}"
    size    = "100"
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
     image = "ubuntu-os-cloud/ubuntu-1804-lts"
     size = "100"
   } 
 }

 metadata {
   sshKeys = "ubuntu:${file("/Users/grant/.ssh/humio-gcp-us-east-1.pub")}"
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
# labels and tags are not the same thing GCP, punting and using tags for now
#  labels = {
#         kafkas = true
#         zookeepers = true
#         humios = true
#  }
}