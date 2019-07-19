


// create an pd-ssd for each humio-host
resource "google_compute_disk" "humio-pd-ssd-a" {
    count   = "${var.instances}"
    name    = "humio-pd-ssd-${count.index + 1}-a-data"
    type    = "pd-ssd"
    zone    = "${var.region}-a"
    size    = "${var.humio_disk_size}"
}

resource "google_compute_instance" "humios-a" {
 count = "${var.instances}"
 name = "${format("humio%02d-%s-a", count.index + 1, var.region)}"
 machine_type = "${var.machine_type}"
 zone         = "${var.region}-a"

 attached_disk {
    source      = "${element(google_compute_disk.humio-pd-ssd-a.*.self_link, count.index +1)}"
    device_name = "${element(google_compute_disk.humio-pd-ssd-a.*.name, count.index + 1)}"
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
        "${count.index < var.zookeepers ? "zookeepers" : "no-zookeepers"}",
        "kafkas",
        "humios"
  ]


 metadata_startup_script = <<SCRIPT
 sudo apt-get update
 sudo apt-get install -yq build-essential python jq
 sudo mkdir -p /etc/ansible/facts.d/
 sudo echo ${count.index + 1} > /etc/ansible/facts.d/cluster_index.fact
 sudo echo -e $(echo ${google_service_account_key.default.private_key} | base64 -d | jq '.private_key') > /var/lib/service-account.key
 sudo chown ubuntu:ubuntu /var/lib/service-account.key
 sudo chmod 600 /var/lib/service-account.key
 SCRIPT
 network_interface {
   network = "${google_compute_network.vpc_network.name}"
    access_config {
      // Ephemeral IP
    }

 }
}
resource "google_compute_instance_group" "humionodes_a" {
  name        = "humio-nodes-a"
  description = "humio-nodes-a"

  instances = ["${google_compute_instance.humios-a.*.self_link}"]

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

  zone = "${var.region}-a"
}
