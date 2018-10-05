provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

resource "packet_project" "humio_performancetest_project" {
  name = "Humio"
}

resource "packet_device" "zk-kafka-humios" {
  count            = "${var.zkh_instances}"
  hostname         = "${format("humio%02d", count.index + 1)}"
  plan             = "${var.humio_plan}"
  facility         = "${var.facility}"
  operating_system = "ubuntu_18_04"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.humio_performancetest_project.id}"
  tags             = ["zookeepers", "kafkas", "humios"]
  user_data        = <<USERDATA
#!/bin/bash
mkdir -p /etc/ansible/facts.d
echo '${count.index + 1}' > /etc/ansible/facts.d/cluster_index.fact
USERDATA

  provisioner "remote-exec" {
    inline = [
      "/bin/mkdir -p /var/humio",
      "/usr/bin/apt update",
      "/usr/bin/apt -y install parted",
      "/sbin/parted -a optimal /dev/nvme0n1 mklabel gpt",
      "/sbin/parted -a optimal /dev/nvme0n1 mkpart primary ext4 0% 100%",
      "sleep 5s",
      "/sbin/mkfs.ext4 /dev/nvme0n1p1",
      "/bin/mount /dev/nvme0n1p1 /var/humio -t ext4"
      //      TODO: Add to /etc/fstab
    ]
  }

}

resource "packet_device" "humios" {
  count            = "${var.humio_instances}"
  hostname         = "${format("humio%02d", count.index + var.zkh_instances + 1)}"
  plan             = "${var.humio_plan}"
  facility         = "${var.facility}"
  operating_system = "ubuntu_18_04"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.humio_performancetest_project.id}"
  tags             = ["kafkas", "humios"]
  user_data        = <<USERDATA
#!/bin/bash
mkdir -p /etc/ansible/facts.d
echo '${count.index + var.zkh_instances + 1}' > /etc/ansible/facts.d/cluster_index.fact
USERDATA

  provisioner "remote-exec" {
    inline = [
      "/bin/mkdir -p /var/humio",
      "/usr/bin/apt update",
      "/usr/bin/apt -y install parted",
      "/sbin/parted -a optimal /dev/nvme0n1 mklabel gpt",
      "/sbin/parted -a optimal /dev/nvme0n1 mkpart primary ext4 0% 100%",
      "sleep 5s",
      "/sbin/mkfs.ext4 /dev/nvme0n1p1",
      "/bin/mount /dev/nvme0n1p1 /var/humio -t ext4"
      //      TODO: Add to /etc/fstab
    ]
  }
}

resource "packet_device" "ingesters" {
  count            = "${var.ingester_instances}"
  hostname         = "${format("ingester%02d",  count.index + 1)}"
  plan             = "${var.ingester_plan}"
  facility         = "${var.facility}"
  operating_system = "ubuntu_18_04"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.humio_performancetest_project.id}"
  tags             = ["ingesters"]
}

