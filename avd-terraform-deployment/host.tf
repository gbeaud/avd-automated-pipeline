locals {
  #registration_token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IkZDMTBFOUQzNUQ4MEFCMjQyMTM2MTJBMDIwQjA3Q0U2Q0UxODRGMDAiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjI3ZGZhMTkxLTkzNzgtNDc4ZC04ZjgwLWU5NmExYmU1MTU0MCIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy1ldS1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLWV1LXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiM2IyNWI1MGYtYTYxNi00Zjc3LTgxYWMtMmNmNzY0ZjNlYTQ3IiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJFVSIsIkdsb2JhbEJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovL3JkYnJva2VyLnd2ZC5taWNyb3NvZnQuY29tLyIsIkJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovL3JkYnJva2VyLWctZXUtcjAud3ZkLm1pY3Jvc29mdC5jb20vIiwiRGlhZ25vc3RpY3NSZXNvdXJjZUlkVXJpIjoiaHR0cHM6Ly9yZGRpYWdub3N0aWNzLWctZXUtcjAud3ZkLm1pY3Jvc29mdC5jb20vIiwibmJmIjoxNjQ0MjQxMzQ3LCJleHAiOjE2NDY4MzMzMzUsImlzcyI6IlJESW5mcmFUb2tlbk1hbmFnZXIiLCJhdWQiOiJSRG1pIn0.Zo2A-X-dKhuXSPcTCOMLr0KEWLmY0mSQLEmApfvtl62IMkFo9WwQ4JUY0B0lWTEHZi5XjhK8ZP3nVbOfrawU7TBUhBQdAVhHcToZebPygVn2GV35PJKH15p6QQWgoP-oLdOcifSZ_XZwqFJPh_98iMLWxE8eP01iuN4Cvqs-Rgus1yeMPvM6kCPPlskviWJdepfNEAAZcAbbxnTNcyoF0HjjpdHlNd3LuNUJOeuYPO6mLq9Orn874JwIrt7qoRf5OEemiLKg6gOtesFoiXRcVGcElvFsfUexSpcyrFO_6HscARkxMZ-o3i8nkBu680lwMn_JijrGmpdc3JkMi2LNIQ"
  # This command creates an error due to a bug in terraform's  registry.terraform.io/hashicorp/azurerm v2.92.0. A workaround is to paste the token in static, but needs to be changed later when the issue is fixed and terraform is updated.
  registration_token = azurerm_virtual_desktop_host_pool.hostpool.registration_info[0].token
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

  os_disk {
    name                 = "${lower(var.prefix)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-evd"
    version   = "latest"
  }

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
