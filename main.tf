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

resource "azurerm_resource_group" "vnet_main" {
  name     = var.resource_group_name
  location = var.location
}

module "vnet-main" {
  source              = "Azure/vnet/azurerm"
  version             = "~> 2.0"
  resource_group_name = azurerm_resource_group.vnet_main.name
  vnet_name           = var.resource_group_name
  address_space       = [var.vnet_cidr_range]
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  nsg_ids             = {}

  tags = {
    environment = "dev"
    costcenter  = "it"

  }

  depends_on = [azurerm_resource_group.vnet_main]
}

#############################################################################
# OUTPUTS
#############################################################################

resource "azurerm_network_interface" "main" {
  count = var.instance_count
  name                = "test1-vm${count.index}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.vnet_main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = element(module.vnet-main.vnet_subnets, 0)
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_virtual_machine" "main" {
  count = var.instance_count
  name                  = var.live == 0 ? "prodtest1-vm${count.index}" : "devtest1-vm${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.vnet_main.name
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

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
      key_data = file("~/projects/Testone/etoro.pub")
      path="/home/jonathan/.ssh/authorized_keys"
    }
    disable_password_authentication = true
  }
}


output "vnet_id" {
  value = module.vnet-main.vnet_id
}

# output "cmd" {
#   value = "ssh jonathan@${element(azurerm_network_interface.main.private_ip_addresses, 0)}"
# }


data "azurerm_virtual_network" "example" {
  name                = "bastion1"
  resource_group_name = "bastion1"
}

output "virtual_network_id" {
  value = data.azurerm_virtual_network.example.id
}

# resource "azurerm_virtual_network" "jonathanbastion1" {
#   name                = "bastion1"
#   location            = var.location
#   resource_group_name = "bastion1"
#   address_space       = ["11.0.0.0/16"]
#   # dns_servers         = ["10.0.0.4", "10.0.0.5"]

#   # ddos_protection_plan {
#   #   id     = azurerm_network_ddos_protection_plan.example.id
#   #   enable = true
#   # }

#   subnet {
#     name           = "AzureBastionSubnet"
#     address_prefix = "11.0.0.0/24"
#   }

#   # subnet {
#   #   name           = "subnet2"
#   #   address_prefix = "10.0.2.0/24"
#   # }

#   # tags = {
#   #   environment = "Production"
#   # }
# }