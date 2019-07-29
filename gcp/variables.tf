# variable "humio_plan" {
#   type = "string"
#   default = "m4.xlarge"
#   description = <<EOS
# The list of Packet machines. Check curl -s -H "Accept: application/json" -H "X-Auth-Token: $\{TF_VAR_packet_auth_token\}" "https://api.packet.net/plans" | jq '.plans[] | [.name, .slug, .description, .pricing.hour]' to see a list of machines
# EOS
# }

# must be set manually
variable "gcp_project_id" {
  type = "string"
}

variable "vpc_network_name" {
  type = "string"
  default = "humio-vpc"
}
variable "vpc_network_cidr" {
  type = "string"
  default = "10.0.0.0/22"
}

# allow access from
variable "access_pub_key" {
  type = "string"
  default = ""
}
variable "ansible_ssh_user" {
  type = "string"
  default = "ubuntu"
}
variable "boot_disk_image" {
  type = "string"
  default = "ubuntu-os-cloud/ubuntu-1804-lts"
}
variable "boot_disk_size" {
  type = "string"
  default = "100"
}

variable "humio_disk_size" {
  type = "string"
  default = "500"
}

variable "kafka_disk_size" {
  type = "string"
  default = "300"
}

variable "zookeeper_disk_size" {
  type = "string"
  default = "50"
}

variable "external_access_ips" {
  type = "list"
  default = []
}

variable "zookeepers" {
  type = "string"
  default = "3"
}
// number of instances per zone

variable "instances" {
  type = "string"
  default = "6"
}
variable "region" {
  type = "string"
  default = "us-central1"
}
# variable "zone" {
#   type = "string"
#   default = "us-east1-b"
# }

variable "machine_type" {
  type = "string"
  default = "n1-standard-8"
  #default = "n1-standard-32"
}


# variable "zones" {
#   type = "string"
#   default = "2"
# }
