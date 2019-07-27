
resource "google_compute_instance" "humio01" {


  name         = "humio01"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-a", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }
  attached_disk {
    source      = "${google_compute_disk.humio01-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio01-pd-ssd-a.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio01-kafka-pd-ssd-a.self_link}"
    device_name = "${google_compute_disk.humio01-kafka-pd-ssd-a.name}"
  }

  scratch_disk {
    interface = "NVME"
  }
  tags = [
    "zookeepers",
    "kafkas",
    "humios"
  ]
    metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 1 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }



}

resource "google_compute_instance" "humio02" {


  name         = "humio02"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-b", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }

  attached_disk {
    source      = "${google_compute_disk.humio02-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio02-pd-ssd-b.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio02-kafka-pd-ssd-b.self_link}"
    device_name = "${google_compute_disk.humio02-kafka-pd-ssd-b.name}"
  }

  scratch_disk {
    interface = "NVME"
  }


  tags = [
    "zookeepers",
    "kafkas",
    "humios"
  ]
    metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 2 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }
}
resource "google_compute_instance" "humio03" {


  name         = "humio03"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-c", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }

  attached_disk {
    source      = "${google_compute_disk.humio03-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio03-pd-ssd-c.name}"
  }

  attached_disk {
    source      = "${google_compute_disk.humio03-kafka-pd-ssd-c.self_link}"
    device_name = "${google_compute_disk.humio03-kafka-pd-ssd-c.name}"
  }

  scratch_disk {
    interface = "NVME"
  }


  tags = [
    "zookeepers",
    "kafkas",
    "humios"
  ]
    metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 3 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }

}


resource "google_compute_instance" "humio04" {


  name         = "humio04"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-a", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }

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
    metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 4 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }

}

resource "google_compute_instance" "humio05" {


  name         = "humio05"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-b", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }

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
    metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 5 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }

}


resource "google_compute_instance" "humio06" {


  name         = "humio06"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-c", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }

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
    metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 6 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }

}


resource "google_compute_instance" "humio07" {


  name         = "humio07"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-a", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }

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
    metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 7 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }

}


resource "google_compute_instance" "humio08" {


  name         = "humio08"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-b", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }


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
    metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 8 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }

}


resource "google_compute_instance" "humio09" {


  name         = "humio09"
  machine_type = "${var.machine_type}"
  zone         = "${format("%s-c", var.region)}"

  boot_disk {
    initialize_params {
      image = "${var.boot_disk_image}"
      size  = "${var.boot_disk_size}"
    }
  }

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
  metadata_startup_script = <<script
  sudo apt-get update
  sudo apt-get install -yq build-essential python jq docker.io
  sudo mkdir -p /etc/ansible/facts.d/
  sudo echo 9 > /etc/ansible/facts.d/cluster_index.fact

  sudo echo ${google_service_account_key.default.private_key} | base64 -d | jq -r '.private_key' > /var/lib/service-account.key
  sudo chown ubuntu:ubuntu /var/lib/service-account.key

  sudo chmod 600 /var/lib/service-account.key
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

  sudo bash -c 'cat << eof > /bootstrap.sh
#!/bin/sh

sudo docker run --rm \
  -v /home/ubuntu/.ssh/authorized_keys:/tmp/authorized_keys \
  -v /var/lib/service-account.key:/service-account.pem \
  -v /var/lib/gce.ini:/etc/ansible/gce.ini \
  humio/ansible
eof'

  sudo chmod +x /bootstrap.sh

  sudo bash -c 'cat << eof > /etc/systemd/system/bootstrap.service
[unit]
description=run ansible
after=network.target
[service]
type=oneshot
execstart=/bootstrap.sh
remainafterexit=true
standardoutput=journal
[install]
wantedby=multi-user.target
eof'
  sudo systemctl daemon-reload
  sudo systemctl start bootstrap.service
  script

  network_interface {
    network = "${google_compute_network.vpc_network.name}"
     access_config {
       // ephemeral ip
     }

  }
}

