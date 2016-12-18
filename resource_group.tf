##-----------------------------------------------
##  Provider configuration
##-----------------------------------------------
provider "azurerm" {
    subscription_id = "${var.azure_subscription_id}"
    client_id       = "${var.azure_client_id}"
    client_secret   = "${var.azure_client_secret}"
    tenant_id       = "${var.azure_tenant_id}"

}

##-----------------------------------------------
##  Setup random id to use in names
##-----------------------------------------------
resource "random_id" "id" {
    byte_length = 4
}

##-----------------------------------------------
##  Resource group configuration
##-----------------------------------------------
resource "azurerm_resource_group" "core" {
    name     = "resource-group-${random_id.id.hex}"
    location = "${var.azure-region}"
}

##-----------------------------------------------
##  Networking configuration
##-----------------------------------------------
resource "azurerm_virtual_network" "net1" {
  name                = "net1"
  resource_group_name = "${azurerm_resource_group.core.name}"
  address_space       = ["${var.cidr}"]
  location            = "${var.azure-region}"
}

resource "azurerm_subnet" "sub1" {
    name = "sub1"
    resource_group_name = "${azurerm_resource_group.core.name}"
    virtual_network_name = "${azurerm_virtual_network.net1.name}"
    address_prefix = "${var.cidr}"
    network_security_group_id = "${azurerm_network_security_group.default.id}"
}

resource "azurerm_network_security_group" "default" {
    name = "default"
    location = "${var.azure-region}"
    resource_group_name = "${azurerm_resource_group.core.name}"

    security_rule {
        name = "RDP_Access"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "tcp"
        source_port_range = "*"
        destination_port_range = "3389"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "win-interface" {
    name = "if-win"
    location = "${var.azure-region}"
    resource_group_name = "${azurerm_resource_group.core.name}"
    dns_servers = ["${var.dns-ip}"]
    network_security_group_id = "${azurerm_network_security_group.default.id}"

    ip_configuration {
        name = "ips-win"
        subnet_id = "${azurerm_subnet.sub1.id}"
        private_ip_address_allocation = "static"
        private_ip_address = "${var.server-ip}"
        public_ip_address_id = "${azurerm_public_ip.win.id}"
    }
}

resource "azurerm_public_ip" "win" {
    name = "win"
    location = "${var.azure-region}"
    resource_group_name = "${azurerm_resource_group.core.name}"
    public_ip_address_allocation = "static"
}

##-----------------------------------------------
##  Storage configuration
##-----------------------------------------------
resource "azurerm_storage_account" "sa" {
    name = "sa${random_id.id.hex}"
    resource_group_name = "${azurerm_resource_group.core.name}"
    location = "${var.azure-region}"
    account_type = "Standard_LRS"
}

resource "azurerm_storage_container" "imgstore" {
    name = "vhds"
    resource_group_name = "${azurerm_resource_group.core.name}"
    storage_account_name = "${azurerm_storage_account.sa.name}"
    container_access_type = "private"
}

##-----------------------------------------------
##  Output IP Address
##-----------------------------------------------

output "external_ip_address" {
    value = "${azurerm_public_ip.win.ip_address}"
}