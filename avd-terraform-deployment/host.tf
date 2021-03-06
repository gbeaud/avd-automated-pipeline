locals {
  registration_token = azurerm_virtual_desktop_host_pool_registration_info.registration_info.token
}

# Getting the custom image from another resource group in the same subscription
# data "azurerm_image" "image" {
#   name                = var.image_name
#   resource_group_name = var.image_resource_group
# }

# Getting the custom image from a compute gallery in another subscription
data "azurerm_shared_image" "shared_image" {
  provider            = azurerm.landing_zone_collaboration_subscription
  name                = var.image_name
  gallery_name        = var.gallery_name
  resource_group_name = var.image_resource_group
}

resource "random_string" "AVD_local_password" {
  count            = var.rdsh_count
  length           = 16
  special          = true
  min_special      = 2
  override_special = "*!@#?"
}

resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.rdsh_count
  name                = "${var.prefix}-${count.index + 1}-nic"
  resource_group_name = var.rg_name
  location            = var.deploy_location

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                 = var.rdsh_count
  name                  = "${var.prefix}-${count.index + 1}"
  resource_group_name   = var.rg_name
  location              = var.deploy_location
  size                  = var.vm_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username        = var.local_admin_username
  admin_password        = var.local_admin_password

  tags = {
    Environment  = "Demo"
    FSLogix      = "Disabled"
    DomainJoined = "AD"
    Image        = "Custom"
    Intune       = "Disabled"
  }

  os_disk {
    name                 = "${lower(var.prefix)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Windows 10 from Marketplace
  # source_image_reference {
  #   publisher = "MicrosoftWindowsDesktop"
  #   offer     = "Windows-10"
  #   sku       = "20h2-evd"
  #   version   = "latest"
  # }

  # Windows 11 multi-session from Marketplace
  # source_image_reference {
  #   publisher = "MicrosoftWindowsDesktop"
  #   offer     = "office-365"
  #   sku       = "win11-21h2-avd-m365"
  #   version   = "latest"
  # }

  # Custom image when residing in same subscription
  # source_image_id = data.azurerm_image.image.id

  # Custom image when residing in a shared image gallery in another subscription
  source_image_id = data.azurerm_shared_image.shared_image.id

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_network_interface.avd_vm_nic
  ]
}

resource "azurerm_virtual_machine_extension" "domain_join" {
  count                      = var.rdsh_count
  name                       = "${var.prefix}-${count.index + 1}-domainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "${var.domain_name}",
      "OUPath": "${var.ou_path}",
      "User": "${var.domain_user_upn}@${var.domain_name}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.domain_password}"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_virtual_network_peering.peer1,
    azurerm_virtual_network_peering.peer2
  ]
}

resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                      = var.rdsh_count
  name                       = "${var.prefix}${count.index + 1}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_3-10-2021.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.hostpool.name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
    azurerm_virtual_desktop_host_pool.hostpool
  ]
}


# resource "azurerm_virtual_machine_extension" "vmext_fslogix-2" {
#   count                      = var.rdsh_count
#   name                       = "${var.prefix}${count.index + 1}-FSLogix"
#   virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
#   publisher                  = "Microsoft.Powershell"
#   type                       = "DSC"
#   type_handler_version       = "2.73"
#   auto_upgrade_minor_version = true

#   # Runs the file "fslogix-config.ps1" contained in the variable fslogix_config_file upon VM creation 
#   protected_settings = <<PROT
#   {
#       "script": "${base64encode(file(var.fslogix_config_file))}"
#   }
#   PROT 

# }

resource "azurerm_virtual_machine_extension" "vmext_fslogix_3" {
  count                = var.rdsh_count
  name                 = "${var.prefix}${count.index + 1}-FSLogix-3"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File fslogix-config.ps1",
        "fileUris": ["https://raw.githubusercontent.com/gbeaud/avd-automated-pipeline/main/avd-terraform-deployment/fslogix-config.ps1"]
    }
SETTINGS

}
