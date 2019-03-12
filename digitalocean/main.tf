provider "digitalocean" {
}

resource "digitalocean_tag" "project" {
  name = "humio-demo"
}
resource "digitalocean_tag" "zookeepers" {
  name = "zookeepers"
}
resource "digitalocean_tag" "no-zookeepers" {
  //todo: Until we have "null" of Terraform 0.12
  name = "no-zookeepers"
}
resource "digitalocean_tag" "kafkas" {
  name = "kafkas"
}
resource "digitalocean_tag" "humios" {
  name = "humios"
}

data "digitalocean_ssh_key" "default" {
  name = "${var.sshkey}"
}

resource "digitalocean_droplet" "humios" {
  count = "${var.instances}"
  image = "${var.image}"
  name = "${format("humio%02d-%s", count.index + 1, var.region)}"
  region = "${var.region}"
  size = "${var.size}"
  private_networking = true
  monitoring = true
  ssh_keys = ["${data.digitalocean_ssh_key.default.fingerprint}"]
  tags = [
        "${digitalocean_tag.project.id}",
        "${count.index < var.zookeepers ? digitalocean_tag.zookeepers.id : digitalocean_tag.no-zookeepers.id}",
        "${digitalocean_tag.kafkas.id}",
        "${digitalocean_tag.humios.id}"
  ]
  user_data = <<USERDATA
#cloud-config
package_upgrade: true
packages:
  - python-minimal
write_files:
  - path: /etc/ansible/facts.d/cluster_index.fact
    content: "${count.index + 1}"
USERDATA
}

resource "digitalocean_loadbalancer" "humio" {
  name = "humio-ui"
  region = "${var.region}"
  "forwarding_rule" {
    entry_port = 80
    entry_protocol = "http"
    target_port = 8080
    target_protocol = "http"
  }

  "forwarding_rule" {
    entry_port = 9200
    entry_protocol = "http"
    target_port = 9200
    target_protocol = "http"
  }

  healthcheck {
    port = 8080
    protocol = "http"
    path = "/api/v1/status"
  }

  droplet_tag = "humios"
}
