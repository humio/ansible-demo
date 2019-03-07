provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

resource "packet_project" "humio_performancetest_project" {
  name = "Humio"
}

resource "packet_device" "humios" {
  count            = "${var.instances}"
  hostname         = "${format("humio%02d-%s", count.index + 1, element(var.facilities, count.index))}"
  plan             = "${var.humio_plan}"
  facility         = "${element(var.facilities, count.index)}"
  operating_system = "ubuntu_18_04"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.humio_performancetest_project.id}"
  tags             = "${compact(list(
    count.index < var.zookeepers ? "zookeepers" : "",
    "kafkas",
    "humios"
  ))}"
  user_data        = <<USERDATA
#!/bin/bash
mkdir -p /etc/ansible/facts.d
echo '${count.index + 1}' > /etc/ansible/facts.d/cluster_index.fact
USERDATA

  provisioner "remote-exec" {
    inline = [
      "apt -y update",
      "apt -y install xfsprogs",
      <<MDADM
mdadm --create /dev/md/primary $(lsblk -OJ | jq -r '.blockdevices[] | select(.rota == "0" and (has("children") | not)) | "/dev/\(.name)"') --level=0 --raid-devices=$(lsblk -OJ | jq '[.blockdevices[] | select(.rota == "0" and (has("children") | not))] | length')
MDADM
    ,
      <<MDADM
mdadm --create /dev/md/secondary $(lsblk -OJ | jq -r '.blockdevices[] | select(.rota == "1") | "/dev/\(.name)"') --level=0 --raid-devices=$(lsblk -OJ | jq '[.blockdevices[] | select(.rota == "1")] | length')
MDADM
    ,
      "mdadm --detail --scan >> /etc/mdadm/mdadm.conf",
      "update-initramfs -u",
      "sleep 5s",
      "mkfs.xfs /dev/md/primary",
      "mkfs.xfs /dev/md/secondary",
    ]
  }
}

resource "packet_device" "ingesters" {
  count            = "${var.ingester_instances}"
  hostname         = "${format("ingester%02d",  count.index + 1)}"
  plan             = "${var.ingester_plan}"
  facility         = "${element(var.ingester_facilities, count.index)}"
  operating_system = "ubuntu_18_04"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.humio_performancetest_project.id}"
  tags             = ["ingesters"]
}

