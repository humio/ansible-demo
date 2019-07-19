


// create an pd-ssd for each humio-host
resource "google_compute_disk" "humio-pd-ssd-b" {
    count   = "${var.instances}"
    name    = "humio-pd-ssd-${count.index + 2}-b-data"
    type    = "pd-ssd"
    zone    = "${var.region}-b"
    size    = "${var.humio_disk_size}"
}

resource "google_compute_instance" "humios-b" {
 count = "${var.instances}"
 name = "${format("humio%02d-%s-b", count.index + 2, var.region)}"
 machine_type = "${var.machine_type}" 
 zone         = "${var.region}-b"

 attached_disk {
    source      = "${element(google_compute_disk.humio-pd-ssd-b.*.self_link, count.index + 2)}"
    device_name = "${element(google_compute_disk.humio-pd-ssd-b.*.name, count.index + 2)}"
 }

 boot_disk {
   initialize_params {
     image = "${var.boot_disk_image}" 
     size = "${var.boot_disk_size}"
   } 
 }

#  metadata {
#    sshKeys = "${var.ansible_ssh_user}:${var.access_pub_key}"
#  }

 tags = [
        "${count.index + 2 < var.zookeepers ? "zookeepers" : "no-zookeepers"}",
        "kafkas",
        "humios"
  ]


 metadata_startup_script = <<SCRIPT
 sudo apt-get update
 sudo apt-get install -yq build-essential python
 sudo mkdir -p /etc/ansible/facts.d/ 
 sudo echo ${count.index + 2} > /etc/ansible/facts.d/cluster_index.fact
 SCRIPT
 network_interface {
   network = "${google_compute_network.vpc_network.name}"
    access_config {
      // Ephemeral IP
    }

 }
}
resource "google_compute_instance_group" "humionodes_b" {
  name        = "humio-nodes-b"
  description = "humio-nodes-b"

  instances = ["${google_compute_instance.humios-b.*.self_link}"]

  named_port {
    name = "http"
    port = "8080"
  }
   named_port {
    name = "https"
    port = "443"
  }


#   named_port {
#     name = "es"
#     port = "9200"
#   }

  zone = "${var.region}-b"
} 
