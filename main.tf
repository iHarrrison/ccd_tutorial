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
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }
}

# Public IP for Web Server
resource "azurerm_public_ip" "web_public_ip" {
  name                = "web-public-ip"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location
  allocation_method   = "Dynamic"
}

# Web Server (Linux Based for Web Serving)
resource "azurerm_linux_virtual_machine" "web_server" {
  name                  = "web-server"
  resource_group_name   = azurerm_resource_group.web_rg.name
  location              = azurerm_resource_group.web_rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "ThisIsAPassword123!"
  network_interface_ids = [azurerm_network_interface.web_nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("./sshtest.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

}

# adds custom script so the web server runs the bash script created

resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "installscript"
  virtual_machine_id   = azurerm_linux_virtual_machine.web_server.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "wget -O /tmp/installing.sh 'https://tutorialccd.blob.core.windows.net/scripts/installing.sh' && bash /tmp/installing.sh"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
        "fileUris": ["https://tutorialccd.blob.core.windows.net/scripts/installing.sh"]
    }
PROTECTED_SETTINGS
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
resource "azurerm_windows_virtual_machine" "app_server" {
  name                  = "app-server"
  resource_group_name   = azurerm_resource_group.web_rg.name
  location              = azurerm_resource_group.web_rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "ThisIsAPassword123!"
  network_interface_ids = [azurerm_network_interface.app_nic.id]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
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

#DB Tier

# MySQL Server
resource "azurerm_mysql_server" "mysql_server" {
  name                         = "db-mysqlserver"
  resource_group_name          = azurerm_resource_group.web_rg.name
  location                     = azurerm_resource_group.web_rg.location
  administrator_login          = "mysqladmin"
  administrator_login_password = "ThisIsAPassword123!"

  sku_name   = "B_Gen5_1"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
}

# MySQL Database
resource "azurerm_mysql_database" "mysql_db" {
  name                = "db-mysql"
  resource_group_name = azurerm_resource_group.web_rg.name
  server_name         = azurerm_mysql_server.mysql_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
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