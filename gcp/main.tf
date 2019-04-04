// Configure 0the Google Cloud provider
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


# resource "google_compute_region_backend_service" "humios" {
#   name             = "humio"
#   description      = "Humio Node"
#   protocol         = "TCP"
#   timeout_sec      = 10
#   # session_affinity = "CLIENT_IP"

#   backend {
#     group = "${google_compute_instance_group.humionodes.self_link}"
#   }

#   health_checks = ["${google_compute_health_check.check8080.self_link}"]
# }
resource "google_compute_forwarding_rule" "humioforwarder" {
  name       = "humio-forwarder"
  target     = "${google_compute_target_pool.humiotargets.self_link}"
  port_range = "8080"
}
resource "google_compute_forwarding_rule" "humioesforwarder" {
  name       = "humio-es-forwarder"
  target     = "${google_compute_target_pool.humioestargets.self_link}"
  port_range = "9200"
}
resource "google_compute_target_pool" "humiotargets" {
  name = "humio-pool"

  instances = ["${google_compute_instance.humios.*.self_link}"]

  health_checks = [
    "${google_compute_http_health_check.default.name}",
  ]
}
resource "google_compute_target_pool" "humioestargets" {
  name = "humio-es-pool"

  instances = ["${google_compute_instance.humios.*.self_link}"]

  health_checks = [
    "${google_compute_http_health_check.es.name}",
  ]
}

resource "google_compute_http_health_check" "default" {
  name               = "default"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
  port = 8080
}
resource "google_compute_http_health_check" "es" {
  name               = "escheck"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
  port = 9200
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
# resource "google_compute_instance_group" "humionodes" {
#   name        = "humio-nodes"
#   description = "humio-nodes"

#   instances = ["${google_compute_instance.humios.*.self_link}"]

#   named_port {
#     name = "http"
#     port = "8080"
#   }

#   named_port {
#     name = "http"
#     port = "9200"
#   }

#   zone = "${var.zone}"
# } 



