# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "myrg" {
  name     = "terraform-challenge"
  location = "eastus"
}
# Create a Virtual Network
resource "azurerm_virtual_network" "tfvnet" {
  name          = "terraform-vnet"
  address_space = ["10.8.0.0/16"]
  resource_group_name = azurerm_resource_group.myrg.name
  location      = azurerm_resource_group.myrg.location
  depends_on =  [azurerm_resource_group.myrg]
}
# Create subnet1
resource "azurerm_subnet" "subnet1" {
  name                 = "snet-dev-eastus-001"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.tfvnet.name
  address_prefixes = [ "10.8.1.0/24" ]
}
# Create subnet2
resource "azurerm_subnet" "subnet2" {
  name                 = "snet-dev-eastus-002"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.tfvnet.name
  address_prefixes = [ "10.8.2.0/24" ]
  service_endpoints = [ "Microsoft.Sql" ]
}
# Create network security group and rule
resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-web-allow-001 "
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  security_rule {
    name                       = "https"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "http"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
########################################################################################
# Create public IP
resource "azurerm_public_ip" "pub_ip01" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  allocation_method   = "Static"
}
# Create Front End Load Balancer
resource "azurerm_lb" "lb_pub_lb" {
  name                = "FrontLoadBalancer"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myrg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pub_ip01.id
  }
}
# Configure Backend Pool for Front End Load Balancer
resource "azurerm_lb_backend_address_pool" "lb_webpool" {
  resource_group_name = azurerm_resource_group.myrg.name
  loadbalancer_id     = azurerm_lb.lb_pub_lb.id
  name                = "BackEndAddressPool"
}
# Configure Health Probe for Front End Load Balancer
resource "azurerm_lb_probe" "lb_https_probe" {
  resource_group_name = azurerm_resource_group.myrg.name
  loadbalancer_id     = azurerm_lb.lb_pub_lb.id
  name                = "https-running-probe"
  port                = 443
}
# Configure Load Balancing rule for Front End Load Balancer
resource "azurerm_lb_rule" "lb_http_rule" {
  resource_group_name            = azurerm_resource_group.myrg.name
  loadbalancer_id                = azurerm_lb.lb_pub_lb.id
  name                           = "LBRuleHTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
}
#########################################################################################
# Create Availability Set
resource "azurerm_availability_set" "web_avset" {
  name                = "web-avset"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
  managed                      = true
}
#Create 2 VMs for FrontEnd
resource "azurerm_network_interface" "web01-nic" {
  name                = "web01-nic"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_windows_virtual_machine" "web01" {
  name                = "web01"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  availability_set_id = azurerm_availability_set.web_avset.id
  network_interface_ids = [
    azurerm_network_interface.web01-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
resource "azurerm_network_interface" "web02-nic" {
  name                = "web02-nic"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_windows_virtual_machine" "web02" {
  name                = "web02"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  availability_set_id = azurerm_availability_set.web_avset.id
  network_interface_ids = [
    azurerm_network_interface.web02-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}


#Install IIS on these VMs
resource "azurerm_virtual_machine_extension" "web02_install_iis" {
  name                       = "web02_install_iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.web02.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell Add-WindowsFeature Web-Asp-Net45;Add-WindowsFeature NET-Framework-45-Core;Add-WindowsFeature Web-Net-Ext45;Add-WindowsFeature Web-ISAPI-Ext;Add-WindowsFeature Web-ISAPI-Filter;Add-WindowsFeature Web-Mgmt-Console;Add-WindowsFeature Web-Scripting-Tools;Add-WindowsFeature Search-Service;Add-WindowsFeature Web-Filtering;Add-WindowsFeature Web-Basic-Auth;Add-WindowsFeature Web-Windows-Auth;Add-WindowsFeature Web-Default-Doc;Add-WindowsFeature Web-Http-Errors;Add-WindowsFeature Web-Static-Content;"
    } 
SETTINGS
}
resource "azurerm_virtual_machine_extension" "web01_install_iis" {
  name                       = "web01_install_iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.web01.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell Add-WindowsFeature Web-Asp-Net45;Add-WindowsFeature NET-Framework-45-Core;Add-WindowsFeature Web-Net-Ext45;Add-WindowsFeature Web-ISAPI-Ext;Add-WindowsFeature Web-ISAPI-Filter;Add-WindowsFeature Web-Mgmt-Console;Add-WindowsFeature Web-Scripting-Tools;Add-WindowsFeature Search-Service;Add-WindowsFeature Web-Filtering;Add-WindowsFeature Web-Basic-Auth;Add-WindowsFeature Web-Windows-Auth;Add-WindowsFeature Web-Default-Doc;Add-WindowsFeature Web-Http-Errors;Add-WindowsFeature Web-Static-Content;"
    } 
SETTINGS
}
############################################################################################
# Create Backend Load Balancer
resource "azurerm_lb" "lb_int_lb" {
  name                = "IntLoadBalancer"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myrg.name

  frontend_ip_configuration {
    name                 = "InternalIPAddress"
    private_ip_address = "10.8.2.10"
    private_ip_address_allocation = "Static"
    subnet_id = azurerm_subnet.subnet2.id
  }
}
# Configure Backend Pool for Back End Load Balancer
resource "azurerm_lb_backend_address_pool" "lb_backendpool" {
  resource_group_name = azurerm_resource_group.myrg.name
  loadbalancer_id     = azurerm_lb.lb_int_lb.id
  name                = "BackEndAddressPool"
}
# Configure Health Probe for Back End Load Balancer
resource "azurerm_lb_probe" "lb_ssh_probe" {
  resource_group_name = azurerm_resource_group.myrg.name
  loadbalancer_id     = azurerm_lb.lb_int_lb.id
  name                = "ssh-running-probe"
  port                = 22
}
# Configure Load Balancing rule for Back End Load Balancer
resource "azurerm_lb_rule" "lb_backendport_rule" {
  resource_group_name            = azurerm_resource_group.myrg.name
  loadbalancer_id                = azurerm_lb.lb_int_lb.id
  name                           = "LBRuleHTTP"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "InternalIPAddress"
}

# Create Availability Set
resource "azurerm_availability_set" "backend_avset" {
  name                = "backend-avset"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
  managed                      = true
}
resource "azurerm_network_interface" "backend01-nic" {
  name                = "backend01-nic"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_virtual_machine" "backend01" {
  name                = "backend01"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  vm_size               = "Standard_B1s"
  availability_set_id = azurerm_availability_set.backend_avset.id
  network_interface_ids = [ azurerm_network_interface.backend01-nic.id ]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "backend01osdisk01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "backend01"
    admin_username = "backendadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_interface" "backend02-nic" {
  name                = "backend02-nic"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_virtual_machine" "backend02" {
  name                = "backend02"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = azurerm_resource_group.myrg.location
  vm_size               = "Standard_B1s"
  availability_set_id = azurerm_availability_set.backend_avset.id
  network_interface_ids = [ azurerm_network_interface.backend02-nic.id ]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "backend02osdisk01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "backend02"
    admin_username = "backendadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

##############################################################################################
#Create Azure SQL DB with Failover Group 
resource "azurerm_sql_server" "primary" {
  name                         = "sql-primary"
  resource_group_name          = azurerm_resource_group.myrg.name
  location                     = azurerm_resource_group.myrg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "pa$$w0rd"
}

resource "azurerm_sql_server" "secondary" {
  name                         = "sql-secondary"
  resource_group_name          = azurerm_resource_group.myrg.name
  location                     = "northeurope"
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "pa$$w0rd"
}

resource "azurerm_sql_database" "db1" {
  name                = "db1"
  resource_group_name = azurerm_sql_server.primary.resource_group_name
  location            = azurerm_sql_server.primary.location
  server_name         = azurerm_sql_server.primary.name
}

resource "azurerm_sql_failover_group" "example" {
  name                = "example-failover-group"
  resource_group_name = azurerm_sql_server.primary.resource_group_name
  server_name         = azurerm_sql_server.primary.name
  databases           = [azurerm_sql_database.db1.id]
  partner_servers {
    id = azurerm_sql_server.secondary.id
  }
  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}