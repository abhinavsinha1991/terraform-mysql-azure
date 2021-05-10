#Provider definition for Azure

provider "azurerm" {
  features {}
}

#Create necessary Azure resources
resource "azurerm_resource_group" "playground-rg" {
  name     = var.myvars.myprefix
  location = var.myvars.location
  /*lifecycle {
    prevent_destroy = true
  }*/
}

resource "azurerm_virtual_network" "playground-vnet" {
  name                = "${var.myvars.myprefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.playground-rg.location
  resource_group_name = azurerm_resource_group.playground-rg.name
}

resource "azurerm_subnet" "playground-sub1" {
  name                 = "${var.myvars.myprefix}-sub1"
  resource_group_name  = azurerm_resource_group.playground-rg.name
  virtual_network_name = azurerm_virtual_network.playground-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "playground-public-ip" {
  name                = "${var.myvars.myprefix}-public-ip"
  resource_group_name = azurerm_resource_group.playground-rg.name
  location            = azurerm_resource_group.playground-rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "playground-nic" {
  name                = "${var.myvars.myprefix}-nic"
  location            = azurerm_resource_group.playground-rg.location
  resource_group_name = azurerm_resource_group.playground-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.playground-sub1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.5"
    public_ip_address_id          = azurerm_public_ip.playground-public-ip.id
  }
}

#NSG with only 2 inbound rules, that too from the machine this script will be run from(derived from data.http.myip)
resource "azurerm_network_security_group" "playground-nsg" {
  name                = "${var.myvars.myprefix}-nsg"
  location            = azurerm_resource_group.playground-rg.location
  resource_group_name = azurerm_resource_group.playground-rg.name

  security_rule {
    name                       = "MySQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "${trim(data.http.myip.body, "\n")}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${trim(data.http.myip.body, "\n")}/32"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "playground-nsg-assoc" {
  network_interface_id      = azurerm_network_interface.playground-nic.id
  network_security_group_id = azurerm_network_security_group.playground-nsg.id
}

#Create VM resource with provisioner to run mysql installation

resource "azurerm_linux_virtual_machine" "playground-mysql" {
  name                = "${var.myvars.myprefix}-mysql"
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

  connection {
    type        = "ssh"
    host        = azurerm_linux_virtual_machine.playground-mysql.public_ip_address
    user        = self.admin_username
    private_key = file("~/.ssh/id_rsa")
    agent       = true
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "echo 'mysql-server mysql-server/root_password password ${var.myvars.mysql-root-password}' | sudo debconf-set-selections",
      "echo 'mysql-server mysql-server/root_password_again password ${var.myvars.mysql-root-password}' | sudo debconf-set-selections",
      "sudo apt install -y mysql-server",
      "sudo systemctl enable mysql",
      "sudo sed -i 's/.*bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf",
      "sudo systemctl restart mysql"
    ]
  }
  provisioner "file" {
    content = templatefile("conf/mysql-whitelist-ip.sh", {
      myprefix            = var.myvars.myprefix
      mysql-user-name     = var.myvars.mysql-user-name
      mysql-user-password = var.myvars.mysql-user-password
      root-pass           = var.myvars.mysql-root-password
      myip                = trim(data.http.myip.body, "\n")
    })
    destination = "~/mysql-whitelist-ip.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/mysql-whitelist-ip.sh",
      "~/mysql-whitelist-ip.sh"
    ]
  }

}

# Fetch current system's public IP
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}


#Output to print VM install status

output "playground-vm-ip" {
  value = azurerm_linux_virtual_machine.playground-mysql.public_ip_address
  #sensitive = true
}

output "playground-mysql-user" {
  value = var.myvars.mysql-root-password
  #sensitive = true
}

output "playground-mysql-password" {
  value = var.myvars.mysql-root-password
  #sensitive = true
}
