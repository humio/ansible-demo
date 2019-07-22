

variable "zones" {
  default = { "0" = "a", "1" = "b", "2" = "c"}
  
}

// create an pd-ssd for each humio-host
resource "google_compute_disk" "humio-pd-ssd" {
    count   = "${var.instances}"
    name    = "humio-pd-ssd-${count.index + 1}-${lookup(var.zones, count.index%3)}-data"
    type    = "pd-ssd"
    zone    = "${var.region}-${lookup(var.zones, count.index%3)}"
    size    = "${var.humio_disk_size}"
}

resource "google_compute_instance" "humios" {
 count = "${var.instances}"
 name = "${format("humio%02d-%s-%s", count.index + 1, var.region, lookup(var.zones, count.index%3))}"
 machine_type = "${var.machine_type}" 
 zone         = "${var.region}-${lookup(var.zones, count.index%3)}"

 attached_disk {
    source      = "${element(google_compute_disk.humio-pd-ssd.*.self_link, count.index)}"
    device_name = "${element(google_compute_disk.humio-pd-ssd.*.name, count.index)}"
 }

 boot_disk {
   initialize_params {
     image = "${var.boot_disk_image}" 
     size = "${var.boot_disk_size}"
   } 
 }
 scratch_disk {
     interface = "nvme"
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
 sudo apt-get install -yq build-essential python
 sudo mkdir -p /etc/ansible/facts.d/ 
 sudo echo ${count.index + 1} > /etc/ansible/facts.d/cluster_index.fact
 SCRIPT
 network_interface {
   network = "${google_compute_network.vpc_network.name}"
    access_config {
      // Ephemeral IP
    }

 }
}
resource "google_compute_instance_group" "humionodes" {
  count = "3"
  name        = "humio-nodes-${lookup(var.zones, count.index%3)}"
  description = "humio-nodes-${lookup(var.zones, count.index%3)}"

  instances = ["${element(google_compute_instance.humios.*.self_link, count.index)}"]

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

  zone = "${var.region}-${lookup(var.zones, count.index%3)}"
} 
