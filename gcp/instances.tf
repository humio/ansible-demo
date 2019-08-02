resource "google_compute_instance_template" "humio" {
  name        = "humio-template"
  description = "This template is used to create humio instances"
  machine_type = "${var.machine_type}"

  disk {
    source_image = "${var.boot_disk_image}"
    disk_size_gb  = "${var.boot_disk_size}"
    auto_delete = true
    boot = true
  }

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }
  }

  metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo hostname | tr -dc '0-9' | sed -e 's/^0*//g' > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.' > /var/lib/service-account.json
  sudo chown ubuntu:ubuntu /var/lib/service-account.*

  sudo chmod 600 /var/lib/service-account.*
  sudo mkdir /home/ubuntu/.ssh; sudo touch /home/ubuntu/.ssh
  sudo chown -r ubuntu:ubuntu /home/ubuntu/.ssh; sudo chmod 700 /home/ubuntu/.ssh

  sudo bash -c 'cat << eof > /var/lib/gce.ini
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
eof'

  sudo bash -c 'cat << eof > /etc/ansible/fetch-saml-settings.sh
#!/bin/bash

declare -r gsutil=/root/google-cloud-sdk/bin/gsutil
declare -r gcloud=/root/google-cloud-sdk/bin/gcloud

\$gcloud auth activate-service-account ${google_service_account.default.email} --key-file /service-account.json
\$gsutil cp gs://humio-saml/saml-config.txt /etc/ansible/saml/saml-config.txt
eof'
  sudo chmod +x /etc/ansible/fetch-saml-settings.sh

  sudo mkdir -p /etc/ansible/saml && touch /etc/ansible/saml/saml-config.txt

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker pull humio/ansible

sudo docker run --rm --net=host \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/service-account.json:/service-account.json \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  -v /etc/ansible/fetch-saml-settings.sh:/etc/ansible/fetch-saml-settings.sh \
  -v /etc/ansible/saml:/etc/ansible/saml \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
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
eof'

  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

}

resource "google_compute_instance_from_template" "humio01" {
  name                     = "humio01"
  zone                     = "${format("%s-a", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio01-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio01-pd-ssd-a.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio01-kafka-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio01-kafka-pd-ssd-a.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio01-zookeeper-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio01-zookeeper-pd-ssd-a.name}"
  }

  scratch_disk {
    interface = "NVME"
  }

  tags = [
    "zookeepers",
    "kafkas",
    "humios"
  ]
}

resource "google_compute_instance_from_template" "humio02" {
  name                     = "humio02"
  zone                     = "${format("%s-b", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio02-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio02-pd-ssd-b.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio02-kafka-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio02-kafka-pd-ssd-b.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio02-zookeeper-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio02-zookeeper-pd-ssd-b.name}"
  }

  scratch_disk {
    interface = "NVME"
  }

  tags = [
    "zookeepers",
    "kafkas",
    "humios"
  ]
}

resource "google_compute_instance_from_template" "humio03" {
  name                     = "humio03"
  zone                     = "${format("%s-c", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio03-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio03-pd-ssd-c.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio03-kafka-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio03-kafka-pd-ssd-c.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio03-zookeeper-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio03-zookeeper-pd-ssd-c.name}"
  }

  scratch_disk {
    interface = "NVME"
  }

  tags = [
    "zookeepers",
    "kafkas",
    "humios"
  ]
}

resource "google_compute_instance_from_template" "humio04" {
  name                     = "humio04"
  zone                     = "${format("%s-a", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio04-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio04-pd-ssd-a.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio04-kafka-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio04-kafka-pd-ssd-a.name}"
  }

  scratch_disk {
    interface = "NVME"
  }


  tags = [
    "kafkas",
    "humios"
  ]
}

resource "google_compute_instance_from_template" "humio05" {
  name                     = "humio05"
  zone                     = "${format("%s-b", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio05-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio05-pd-ssd-b.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio05-kafka-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio05-kafka-pd-ssd-b.name}"
  }

  scratch_disk {
    interface = "NVME"
  }

  tags = [
    "kafkas",
    "humios"
  ]
}

resource "google_compute_instance_from_template" "humio06" {
  name                     = "humio06"
  zone                     = "${format("%s-c", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio06-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio06-pd-ssd-c.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio06-kafka-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio06-kafka-pd-ssd-c.name}"
  }

  scratch_disk {
    interface = "NVME"
  }

  tags = [
    "humios"
  ]
}

resource "google_compute_instance_from_template" "humio07" {
  name                     = "humio07"
  zone                     = "${format("%s-a", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio07-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio07-pd-ssd-a.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio07-kafka-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio07-kafka-pd-ssd-a.name}"
  }

  scratch_disk {
    interface = "NVME"
  }

  tags = [
    "humios"
  ]
}

resource "google_compute_instance_from_template" "humio08" {
  name                     = "humio08"
  zone                     = "${format("%s-b", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio08-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio08-pd-ssd-b.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio08-kafka-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio08-kafka-pd-ssd-b.name}"
  }

  scratch_disk {
    interface = "NVME"
  }

  tags = [
    "humios"
  ]
}

resource "google_compute_instance_from_template" "humio09" {
  name                     = "humio09"
  zone                     = "${format("%s-c", var.region)}"
  source_instance_template = "${google_compute_instance_template.humio.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio09-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio09-pd-ssd-c.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio09-kafka-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio09-kafka-pd-ssd-c.name}"
  }

  scratch_disk {
    interface = "NVME"
  }

  tags = [
    "humios"
  ]
}
