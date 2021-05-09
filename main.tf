#Provider definition for Azure

provider "azurerm" {
  features {}
}

locals {

myprefix = "playground"

}

resource "azurerm_resource_group" "playground-rg" {
  name     = "playground"
  location = "East US"
}

resource "azurerm_virtual_network" "playground-vnet" {
  name                = "${local.myprefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.playground-rg.location
  resource_group_name = azurerm_resource_group.playground-rg.name
}

resource "azurerm_subnet" "playground-sub1" {
  name                 = "${local.myprefix}-sub1"
  resource_group_name  = azurerm_resource_group.playground-rg.name
  virtual_network_name = azurerm_virtual_network.playground-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "playground-nic" {
  name                = "${local.myprefix}-nic"
  location            = azurerm_resource_group.playground-rg.location
  resource_group_name = azurerm_resource_group.playground-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.playground-sub1.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.2.5"
  }
}

#Create VM resource with provisioner to run mysql installation

resource "azurerm_linux_virtual_machine" "playground-mysql" {
  name                = "${local.myprefix}-mysql"
  resource_group_name = azurerm_resource_group.playground-rg.name
  location            = azurerm_resource_group.playground-rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.playground-nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

}
#Output to print VM install status

output "playground-vm-output" {
 value = azurerm_linux_virtual_machine.playground-mysql
 sensitive = true
}
