variable "packet_auth_token" {
  type = "string"
}

variable "facility" {
  type = "string"
  default = "ams1"
}

variable "plan" {
  type = "string"
  default = "baremetal_1"
  description = <<EOS
The list of Packet machines. Check curl -s -h "Accept: application/json" -h "X-Auth-Token: $\{TF_VAR_packet_auth_token\}" "https://api.packet.net/plans" | jq '.plans[] | [.name, .slug, .description, .pricing.hour]' to see a list of machines
EOS
}

variable "humio_instances" {
  type = "string"
  default = "3"
}
provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

resource "packet_project" "humio_performancetest_project" {
  name = "Humio"
}

resource "packet_device" "humios" {
  count            = "${var.humio_instances}"
  hostname         = "${format("humio%02d",  count.index + 1)}"
  plan             = "${var.plan}"
  facility         = "${var.facility}"
  operating_system = "ubuntu_18_04"
  billing_cycle    = "hourly"
  project_id       = "${packet_project.humio_performancetest_project.id}"
  tags             = ["zookeepers", "kafkas", "humios"]

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/ansible/facts.d",
      "echo '${count.index+1}' > /etc/ansible/facts.d/cluster_index.fact"
    ]
  }
}

