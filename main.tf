#############################################################################
# TERRAFORM CONFIG
#############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
    backend "azurerm" {
        resource_group_name  = "test1"
        storage_account_name = "tfstatejonathanz"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
    }
}


#############################################################################
# PROVIDERS
#############################################################################

provider "azurerm" {
  features {}
}

#############################################################################
# RESOURCES
#############################################################################

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

module "vnet-main" {
  source              = "Azure/vnet/azurerm"
  version             = "~> 2.0"
  resource_group_name = azurerm_resource_group.main.name
  vnet_name           = var.resource_group_name
  address_space       = [var.vnet_cidr_range]
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  nsg_ids             = {}

  tags = {
    environment = "dev"
    costcenter  = "it"

  }

  depends_on = [azurerm_resource_group.main]
}

#############################################################################
# OUTPUTS
#############################################################################

resource "azurerm_network_interface" "main" {
  count = var.instance_count
  name                = "test1-vm${count.index}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = element(module.vnet-main.vnet_subnets, 0)
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network_peering" "first" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = module.vnet-main.vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.bastion.id
}

# resource "azurerm_virtual_network_peering" "example-2" {
#   name                      = "peer2to1"
#   resource_group_name       = azurerm_resource_group.example.name
#   virtual_network_name      = azurerm_virtual_network.example-2.name
#   remote_virtual_network_id = azurerm_virtual_network.example-1.id
# }


data "azurerm_key_vault" "main" {
  name                = "jonathanz-key-vault-1910"
  resource_group_name = "test1"
}

data "azurerm_key_vault_secret" "main" {
  name         = "etoropublic"
  key_vault_id = data.azurerm_key_vault.main.id
}

resource "azurerm_virtual_machine" "main" {
  count = var.instance_count
  name                  = var.live == 0 ? "prodtest1-vm${count.index}" : "devtest1-vm${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "workplease"
    admin_username  = "jonathan"
  }
  os_profile_linux_config {
    ssh_keys {
      key_data = data.azurerm_key_vault_secret.main.value
      path="/home/jonathan/.ssh/authorized_keys"
    }
    disable_password_authentication = true
  }
}


data "azurerm_virtual_network" "bastion" {
  name                = "bastion1"
  resource_group_name = "bastion1"
}

output "bastion_virtual_network_id" {
  value = data.azurerm_virtual_network.bastion.id
}

output "vnet_id" {
  value = module.vnet-main.vnet_id
}

output "cmd" {
  value = "ssh jonathan@${azurerm_network_interface.main[0].private_ip_addresses[0]}"
}
