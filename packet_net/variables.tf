variable "packet_auth_token" {
  type = "string"
}

variable "facilities" {
  type = "list"
  default = [
    "ewr1"
  ]
}

variable "humio_plan" {
  type = "string"
  default = "s1.large.x86"
  description = <<EOS
The list of Packet machines. Check curl -s -H "Accept: application/json" -H "X-Auth-Token: $\{TF_VAR_packet_auth_token\}" "https://api.packet.net/plans" | jq '.plans[] | [.name, .slug, .description, .pricing.hour]' to see a list of machines
EOS
}

variable "instances" {
  type = "string"
  default = "8"
}

variable "zookeepers" {
  type = "string"
  default = "3"
}

variable "ingester_instances" {
  type = "string"
  default = "0"
}

variable "ingester_facilities" {
  type = "list"
  default = [
    "ewr1"
  ]
}


variable "ingester_plan" {
  type = "string"
  default = "t1.small.x86"
  description = <<EOS
The list of Packet machines. Check curl -s -H "Accept: application/json" -H "X-Auth-Token: $\{TF_VAR_packet_auth_token\}" "https://api.packet.net/plans" | jq '.plans[] | [.name, .slug, .description, .pricing.hour]' to see a list of machines
EOS
}