variable "humio_plan" {
  type        = string
  default     = "m4.xlarge"
  description = <<EOS
The list of Packet machines. Check curl -s -H "Accept: application/json" -H "X-Auth-Token: $\{TF_VAR_packet_auth_token\}" "https://api.packet.net/plans" | jq '.plans[] | [.name, .slug, .description, .pricing.hour]' to see a list of machines
EOS

}

variable "aws_key_name" {
  type = string
}

variable "aws_vpc_cidr_block" {
  type    = string
  default = "172.16.0.0/16"
}

variable "aws_name_prefix" {
  type    = string
  default = ""
}

variable "aws_ami_filter" {
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
  description = <<DESCRIPTION
Options:
* ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*
* RHEL-7.5_HVM_GA-*-x86_64-1-Hourly2-GP2
DESCRIPTION

}

variable "zookeepers" {
  type    = string
  default = "3"
}

variable "instances" {
  type    = string
  default = "8"
}

variable "zones" {
  type    = string
  default = "2"
}

