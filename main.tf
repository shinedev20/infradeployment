
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
    backend "azurerm" {
        #resource_group_name  = "dowd-devops-rg"
        #storage_account_name = "dowdtf"
        #container_name       = "tfstatedowd"
        #key                  = "terraform.tfstate"
    }

}



provider "azurerm" {
  # Configuration options
  features {}
}

# creating resource group
resource "azurerm_resource_group" "rg0123" {

  location = var.location
  name     = join("-", [var.env, var.reg, var.dom,"rg",var.index])
}


resource "azurerm_virtual_network" "vnet" {
  name                = join("-", [var.env, var.reg, var.dom,"vnet",var.index])
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg0123.name
}

resource "azurerm_subnet" "subnet" {
  name                 = join("-", [var.env, var.reg, var.dom,"subnet",var.index])
  resource_group_name  = azurerm_resource_group.rg0123.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}


output "subnet" {
  value = "azurerm_subnet.subnet.id"
}

resource "azurerm_subnet" "subnet1" {
  name                 = join("-", [var.env, var.reg, var.dom,"subnet",var.index1])
  resource_group_name  = azurerm_resource_group.rg0123.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}
output "subnet1" {
  value = "azurerm_subnet.subnet1.id"
}


/*

resource "azurerm_network_interface" "nic" {
  name                = join("-", [var.env, var.reg, var.dom,"nic",var.index])
  location            = var.location
  resource_group_name = azurerm_resource_group.rg0123.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = join("-", [var.env, var.reg, var.dom,"vm",var.index])
  resource_group_name = azurerm_resource_group.rg0123.name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = var.adminlogin
  admin_password      = var.loginpassword
  network_interface_ids = [
    azurerm_network_interface.nic.id,
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

*/

resource "azurerm_resource_group" "rg013" {

  location = var.location
  name     = join("-", [var.env, var.reg, var.dom,"rg",var.index1])
}

resource "azurerm_storage_account" "stg1" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.location
  name                     = join("", [var.env, var.reg, var.dom, "stg", var.index1])
  resource_group_name      = azurerm_resource_group.rg013.name
  depends_on = [azurerm_resource_group.rg013,azurerm_virtual_network.vnet]
}
resource "azurerm_storage_account_network_rules" "test" {
  storage_account_id = azurerm_storage_account.stg1.id

  default_action             = "Deny"
  ip_rules                   = ["127.0.0.1"]
  virtual_network_subnet_ids = [azurerm_subnet.subnet.id,azurerm_subnet.subnet1.id]
  bypass                     = ["Metrics"]
}
resource "azurerm_user_assigned_identity" "example" {
  resource_group_name = azurerm_resource_group.rg0123.name
  location            = var.location

  name = join("-", [var.env, var.reg,"mi"])
}


resource "azurerm_postgresql_server" "psql" {
  name                = join("",[var.env,var.reg,var.dom,"psql", var.index])
  location            = var.location
  resource_group_name = azurerm_resource_group.rg0123.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = var.adminlogin
  administrator_login_password = var.loginpassword
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_database" "psqldb" {
  name                = join("",[var.env,var.reg,var.dom,"psqldb", var.index])
  resource_group_name = azurerm_resource_group.rg0123.name
  server_name         = azurerm_postgresql_server.psql.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}
resource "azurerm_postgresql_firewall_rule" "psqlfw" {
  name                = "office"
  resource_group_name = azurerm_resource_group.rg0123.name
  server_name         = azurerm_postgresql_server.psql.name
  start_ip_address    = "40.112.8.12"
  end_ip_address      = "40.112.8.12"
}



