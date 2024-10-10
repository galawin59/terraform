
data "azurerm_resource_group" "rg" {
  name     = "de_p1_resource_group"
  
}

data "azurerm_service_plan" "service_plan" {
  name = "de_p1_service_plan"
  resource_group_name = data.azurerm_resource_group.rg.name
}
# Create network interface
data "azurerm_network_interface" "my_terraform_nic" {
  name                = "baudry_patrick_nic"

  resource_group_name = data.azurerm_resource_group.rg.name

}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = data.azurerm_resource_group.rg.name
  }

  byte_length = 8
}




resource "azurerm_linux_web_app" "example" {
  name                = "examplebaudry"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  service_plan_id     = data.azurerm_service_plan.service_plan.id

  site_config {}
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "storagebaudry"
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
}
resource "azurerm_storage_container" "my_storage_container" {
  name                  = "containerbaudry"
  storage_account_name  = azurerm_storage_account.my_storage_account.name
  container_access_type = "private"
}
resource "azurerm_storage_blob" "my_storage_blob" {

  name                   = "my-awesome-content.zip"
  storage_account_name   = azurerm_storage_account.my_storage_account.name
  storage_container_name = azurerm_storage_container.my_storage_container.name
  type                   = "Block"
  source                 = "terraform.tfstate"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "baudry_patrick_vm"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [data.azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"
  disable_password_authentication = false
  admin_password = "Admin1234!"

  os_disk {
    name                 = "myOsDiskpatrick"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = var.username

  

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}