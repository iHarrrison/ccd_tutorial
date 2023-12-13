# Azure Provider Configuration
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "web_rg" {
  name     = "web-rg"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "web_vnet" {
  name                = "web-vnet"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Subnets
resource "azurerm_subnet" "web_subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.web_rg.name
  virtual_network_name = azurerm_virtual_network.web_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Interface for Web Server
resource "azurerm_network_interface" "web_nic" {
  name                = "web-nic"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location

  ip_configuration {
    name                          = "web-ipconfig"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Web Server
resource "azurerm_virtual_machine" "web_server" {
  name                  = "web-server"
  resource_group_name   = azurerm_resource_group.web_rg.name
  location              = azurerm_resource_group.web_rg.location
  vm_size               = "Standard_B1s" # A cost-effective VM size for learning
  network_interface_ids = [azurerm_network_interface.web_nic.id]

  os_profile {
    computer_name  = "web-server"
    admin_username = "adminuser"
    admin_password = "Password1234!" # In the real world, this needs to be replaced with a strong password
  }
  
  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}

# Network Interface for App Server
resource "azurerm_network_interface" "app_nic" {
  name                = "app-nic"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location

  ip_configuration {
    name                          = "app-ipconfig"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# App Server
resource "azurerm_virtual_machine" "app_server" {
  name                  = "app-server"
  resource_group_name   = azurerm_resource_group.web_rg.name
  location              = azurerm_resource_group.web_rg.location
  vm_size               = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.app_nic.id]

  os_profile {
    computer_name  = "app-server"
    admin_username = "adminuser"
    admin_password = "Password1234!" # Replace with a strong password
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}

# Network Interface for Database Server
resource "azurerm_network_interface" "db_nic" {
  name                = "db-nic"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location

  ip_configuration {
    name                          = "db-ipconfig"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Database Server
resource "azurerm_virtual_machine" "db_server" {
  name                  = "db-server"
  resource_group_name   = azurerm_resource_group.web_rg.name
  location              = azurerm_resource_group.web_rg.location
  vm_size               = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.db_nic.id]

  os_profile {
    computer_name  = "db-server"
    admin_username = "adminuser"
    admin_password = "Password1234!" # Replace with a strong password
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}

# Web Tier NSG
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location
}

# Inbound Rule to Allow HTTP Traffic
resource "azurerm_network_security_rule" "web_inbound_http" {
  name                        = "web-inbound-http"
  resource_group_name         = azurerm_resource_group.web_rg.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Outbound Rule to Allow All Traffic
resource "azurerm_network_security_rule" "web_outbound_all" {
  name                        = "web-outbound-all"
  resource_group_name         = azurerm_resource_group.web_rg.name
  network_security_group_name = azurerm_network_security_group.web_nsg.name
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# App Tier NSG
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location
}

# Inbound Rule to Allow Communication from Web Tier
resource "azurerm_network_security_rule" "app_inbound_web" {
  name                        = "app-inbound-web"
  resource_group_name         = azurerm_resource_group.web_rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_virtual_network.web_vnet.address_space[0]
  destination_address_prefix  = "*"
}

# Outbound Rule to Allow All Traffic
resource "azurerm_network_security_rule" "app_outbound_all" {
  name                        = "app-outbound-all"
  resource_group_name         = azurerm_resource_group.web_rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Database Tier NSG
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location
}

# Inbound Rule to Allow Communication from App Tier
resource "azurerm_network_security_rule" "db_inbound_app" {
  name                        = "db-inbound-app"
  resource_group_name         = azurerm_resource_group.web_rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_virtual_network.web_vnet.address_space[0]
  destination_address_prefix  = "*"
}

# Outbound Rule to Allow All Traffic
resource "azurerm_network_security_rule" "db_outbound_all" {
  name                        = "db-outbound-all"
  resource_group_name         = azurerm_resource_group.web_rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}