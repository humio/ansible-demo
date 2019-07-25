

variable "zones" {
  default = { "0" = "a", "1" = "b", "2" = "c"}
}

variable "instances_per_zone" {
  default = 2
}

// create an pd-ssd for each humio-host
resource "google_compute_disk" "humio-pd-ssd" {
    count   = "${var.instances}"
    name    = "humio-pd-ssd-${count.index + 1}-${lookup(var.zones, count.index % var.instances / var.instances_per_zone)}-data"
    type    = "pd-ssd"
    zone    = "${var.region}-${lookup(var.zones, count.index % var.instances / var.instances_per_zone)}"
    size    = "${var.humio_disk_size}"
}

resource "google_compute_instance" "humios" {
 count = "${var.instances}"
 name = "${format("humio%02d-%s-%s", count.index + 1, var.region, lookup(var.zones, count.index % var.instances / var.instances_per_zone))}"
 machine_type = "${var.machine_type}"
 zone         = "${var.region}-${lookup(var.zones, count.index % var.instances / var.instances_per_zone)}"

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
     interface = "NVME"
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
 sudo apt-get install -yq build-essential python jq docker.io
 sudo mkdir -p /etc/ansible/facts.d/
 sudo echo ${count.index + 1} > /etc/ansible/facts.d/cluster_index.fact

 sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
 sudo chown ubuntu:ubuntu /var/lib/service-account.key

 sudo chmod 600 /var/lib/service-account.key
 sudo mkdir /home/ubuntu/.ssh; sudo touch /home/ubuntu/.ssh
 sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh; sudo chmod 700 /home/ubuntu/.ssh

 sudo bash -c 'cat << EOF > /var/lib/gce.ini
[gce]
libcloud_secrets =

gce_service_account_email_address = ${google_service_account.default.email}
gce_service_account_pem_file_path = /service-account.pem
gce_project_id = ${var.gcp_project_id}
gce_zone = ${var.region}

[inventory]
inventory_ip_type = internal

[cache]
cache_path = ~/.ansible/tmp
cache_max_age = 300
EOF'

 sudo bash -c 'cat << EOF > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
EOF'

 sudo chmod +x /bootstrap.sh

 sudo bash -c 'cat << EOF > /etc/systemd/system/bootstrap.service
[Unit]
Description=Run Ansible
After=network.target
[Service]
Type=oneshot
ExecStart=/bootstrap.sh
RemainAfterExit=true
StandardOutput=journal
[Install]
WantedBy=multi-user.target
EOF'
 sudo systemctl daemon-reload
 sudo systemctl start bootstrap.service
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
  name        = "humio-nodes-${lookup(var.zones, count.index % 3)}"
  description = "humio-nodes-${lookup(var.zones, count.index % 3)}"

  instances = ["${slice(google_compute_instance.humios.*.self_link, count.index * var.instances_per_zone, count.index * var.instances_per_zone + var.instances_per_zone)}"]

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

  zone = "${var.region}-${lookup(var.zones, count.index % 3)}"
}
