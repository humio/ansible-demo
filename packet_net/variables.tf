variable "packet_auth_token" {
  type = "string"
}

variable "facility" {
  type = "string"
  default = "ams1"
}

variable "humio_plan" {
  type = "string"
  default = "m2.xlarge.x86"
  description = <<EOS
The list of Packet machines. Check curl -s -H "Accept: application/json" -H "X-Auth-Token: $\{TF_VAR_packet_auth_token\}" "https://api.packet.net/plans" | jq '.plans[] | [.name, .slug, .description, .pricing.hour]' to see a list of machines
EOS
}

variable "zkh_instances" {
  type = "string"
  default = "3"
}
variable "humio_instances" {
  type = "string"
  default = "5"
}

variable "ingester_instances" {
  type = "string"
  default = "0"
}

variable "ingester_plan" {
  type = "string"
  default = "baremetal_1"
  description = <<EOS
The list of Packet machines. Check curl -s -H "Accept: application/json" -H "X-Auth-Token: $\{TF_VAR_packet_auth_token\}" "https://api.packet.net/plans" | jq '.plans[] | [.name, .slug, .description, .pricing.hour]' to see a list of machines
EOS
}