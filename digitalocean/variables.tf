variable "sshkey" {
  type = "string"
}

variable "instances" {
  type = "string"
  default = "3"
}

variable "zookeepers" {
  type = "string"
  default = "3"
}

variable "image" {
  type = "string"
  default = "ubuntu-18-04-x64"
}

variable "region" {
  type = "string"
  default = "ams3"
}

variable "size" {
  type = "string"
  default = "s-4vcpu-8gb"
}