variable "azure_resource_group" {
  type        = string
  default     = "humio-ansible-demo"
  description = "Name of the resource group within the target Azure subscription. This will also be used as part of the domain name label."
}

variable "vnet_address_prefix" {
  type        = string
  default     = "172.16.0.0/23"
  description = "Address prefix for the entire virtual network. Must be large enough to contain both frontend subnet and internal subnet."
}

variable "frontend_subnet_prefix" {
  type        = string
  default     = "172.16.0.0/24"
  description = "IP range for the frontend IP of application gateway. Must be part of the vnet address prefix."
}

variable "internal_subnet_prefix" {
  type        = string
  default     = "172.16.1.0/24"
  description = "IP range for the internal network between virtual machines. Must be part of the vnet address prefix."
}

variable "zones" {
  type        = number
  default     = 3
  description = "Number of availability zones to use."
}

variable "instances" {
  type        = number
  default     = 6
  description = "Total instance count to run across all availability zones."
}

variable "zookeepers" {
  type        = number
  default     = 3
  description = "Number of instances to run Zookeeper on. This must be at most the total number of instances."
}

variable "vm_size" {
  type        = string
  default     = "Standard_D4s_v3"
  description = ""
}

variable "ssh_key_data" {
  type        = string
  default     = "none"
  description = ""
}
