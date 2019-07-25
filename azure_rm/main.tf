provider "azurerm" {
  version = "1.31"
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.main.name}-beap"
  frontend_ip_configuration_name = "${azurerm_virtual_network.main.name}-feip"
  frontend_port_name             = "${azurerm_virtual_network.main.name}-feport"
  http_setting_name              = "${azurerm_virtual_network.main.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.main.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.main.name}-rqrt"

  public_ports = {
    ui             = 80
    ingest-api     = 8080
    ingest-elastic = 9200
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.azure_resource_group
  location = "North Europe"
}

resource "azurerm_public_ip" "main" {
  count               = var.instances
  name                = format("humio%02d-ip", count.index + 1)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  zones               = [(count.index % var.zones) + 1]
}

resource "azurerm_virtual_network" "main" {
  name                = "humio-vnet"
  address_space       = [var.vnet_address_prefix]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "frontend" {
  name                 = "humio-frontend"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = var.frontend_subnet_prefix
}

resource "azurerm_subnet" "internal" {
  name                 = "humio-internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = var.internal_subnet_prefix
}

resource "azurerm_network_interface" "main" {
  count                     = var.instances
  name                      = format("humio%02d-nic", count.index + 1)
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  network_security_group_id = azurerm_network_security_group.main.id

  ip_configuration {
    name                          = "ip-configuration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.internal.address_prefix, count.index+11)
    public_ip_address_id          = element(azurerm_public_ip.main.*.id, count.index)
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "humio-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "humio-9200"
    priority                   = 450
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "zookeeper-2181"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "2181"
    destination_port_range     = "2181"
    source_address_prefix      = var.internal_subnet_prefix
    destination_address_prefix = var.internal_subnet_prefix
  }

  security_rule {
    name                       = "zookeeper-2888"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "2888"
    destination_port_range     = "2888"
    source_address_prefix      = var.internal_subnet_prefix
    destination_address_prefix = var.internal_subnet_prefix
  }

  security_rule {
    name                       = "zookeeper-3888"
    priority                   = 220
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3888"
    destination_port_range     = "3888"
    source_address_prefix      = var.internal_subnet_prefix
    destination_address_prefix = var.internal_subnet_prefix
  }

  security_rule {
    name                       = "kafka-9092"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "9092"
    destination_port_range     = "9092"
    source_address_prefix      = var.internal_subnet_prefix
    destination_address_prefix = var.internal_subnet_prefix
  }

  security_rule {
    name                       = "humio-8080"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_machine" "main" {
  count                 = var.instances
  name                  = format("humio%02d-vm", count.index + 1)
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  vm_size               = var.vm_size
  zones                 = [(count.index % var.zones) + 1]

  # These lines will delete the OS disk and the data disk automatically when deleting the VM
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = format("humio%02d-osDisk", count.index + 1)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = format("humio%02d", count.index + 1)
    admin_username = "azureuser"
    admin_password = "azureuser"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = var.ssh_key_data
    }
  }
  tags = {
    cluster_index = count.index + 1
    zookeeper     = count.index < var.zookeepers ? "yes" : "no"
  }
}

resource "azurerm_public_ip" "appgw" {
  name                = "humio-lb-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  domain_name_label   = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_application_gateway" "main" {
  name                = "humio-appgw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  zones               = range(1, var.zones + 1)
  enable_http2        = true

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 3
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration1"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  probe {
    interval                                  = 1
    name                                      = "probe-8080"
    protocol                                  = "Http"
    path                                      = "/api/v1/status"
    timeout                                   = 5
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  probe {
    interval                                  = 1
    name                                      = "probe-9200"
    protocol                                  = "Http"
    path                                      = "/"
    timeout                                   = 5
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}-ui"
    cookie_based_affinity = "Enabled"
    affinity_cookie_name  = "lb_cookie"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 1
    probe_name            = "probe-8080"
    host_name             = azurerm_public_ip.appgw.fqdn
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}-ingest"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 1
    probe_name            = "probe-8080"
    host_name             = azurerm_public_ip.appgw.fqdn
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}-es"
    cookie_based_affinity = "Disabled"
    port                  = 9200
    protocol              = "Http"
    request_timeout       = 1
    probe_name            = "probe-9200"
    host_name             = azurerm_public_ip.appgw.fqdn
  }

  dynamic "frontend_port" {
    for_each = local.public_ports
    content {
      name = format("%s-%s", local.frontend_port_name, frontend_port.key)
      port = frontend_port.value
    }
  }

  dynamic "http_listener" {
    for_each = local.public_ports
    content {
      name                           = format("%s-%s", local.listener_name, http_listener.key)
      frontend_port_name             = format("%s-%s", local.frontend_port_name, http_listener.key)
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      protocol                       = "Http"
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.public_ports
    content {
      name                       = format("%s-%s", local.request_routing_rule_name, request_routing_rule.key)
      http_listener_name         = format("%s-%s", local.listener_name, request_routing_rule.key)
      backend_http_settings_name = format("%s-%s", local.http_setting_name, request_routing_rule.key)
      backend_address_pool_name  = local.backend_address_pool_name
      rule_type                  = "Basic"
    }
  }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "ui" {
  count                   = var.instances
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  ip_configuration_name   = "ip-configuration1"
  backend_address_pool_id = azurerm_application_gateway.main.backend_address_pool.0.id
}


output "humio_ui" {
  value = "http://${azurerm_public_ip.appgw.fqdn}"
}

output "humio_ingest_api" {
  value = "http://${azurerm_public_ip.appgw.fqdn}:8080"
}

output "humio_ingest_elastic" {
  value = "http://${azurerm_public_ip.appgw.fqdn}:9200"
}
