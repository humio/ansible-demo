resource "google_compute_instance_template" "humioingest" {
  name        = "humio-ingest-template"
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

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    email  = "${google_service_account.default.email}"
  }

  metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo hostname | tr -dc '0-9' | sed -e 's/^0*//g' > /etc/ansible/facts.d/cluster_index.fact
  echo \"${var.public_url}\" > /etc/ansible/facts.d/public_url.fact

  sudo mkdir /home/ubuntu/.ssh; sudo touch /home/ubuntu/.ssh
  sudo chown -r ubuntu:ubuntu /home/ubuntu/.ssh; sudo chmod 700 /home/ubuntu/.ssh

  sudo bash -c 'cat << eof > /var/lib/gce.ini
[gce]
libcloud_secrets =

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

\$gsutil cp gs://${var.gcp_project_id}-saml/saml-config.txt /etc/ansible/saml/saml-config.txt
\$gsutil cp gs://${var.gcp_project_id}-saml/saml-cert.pem /etc/ansible/saml/saml-cert.pem
eof'
  sudo chmod +x /etc/ansible/fetch-saml-settings.sh

  sudo mkdir -p /etc/ansible/saml && touch /etc/ansible/saml/saml-config.txt
  sudo mkdir -p /etc/ansible/saml && touch /etc/ansible/saml/saml-cert.pem

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker pull humio/ansible

sudo docker run --rm --net=host \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
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
resource "google_compute_instance_from_template" "humio10" {
  name                     = "humio10"
  zone                     = "${format("%s-a", var.region)}"
  source_instance_template = "${google_compute_instance_template.humioingest.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio10-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio10-pd-ssd-a.name}"
  }

  tags = [
    "humioingest"
  ]
}

resource "google_compute_instance_from_template" "humio11" {
  name                     = "humio11"
  zone                     = "${format("%s-b", var.region)}"
  source_instance_template = "${google_compute_instance_template.humioingest.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio11-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio11-pd-ssd-b.name}"
  }


  tags = [
    "humioingest"
  ]
}

resource "google_compute_instance_from_template" "humio12" {
  name                     = "humio12"
  zone                     = "${format("%s-c", var.region)}"
  source_instance_template = "${google_compute_instance_template.humioingest.self_link}"

  attached_disk {
    source      = "${google_compute_disk.humio12-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio12-pd-ssd-c.name}"
  }

  tags = [
    "humioingest"
  ]
}
