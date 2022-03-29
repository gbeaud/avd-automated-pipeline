resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-VNet"
  address_space       = var.vnet_range
  dns_servers         = var.dns_servers
  location            = var.deploy_location
  resource_group_name = var.rg_name
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_range
  depends_on           = [azurerm_resource_group.rg]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-NSG"
  location            = var.deploy_location
  resource_group_name = var.rg_name
  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Peering with Active Directory VNet
#The "provider" block refers to the other subscription (identity) defined in provider.tf
data "azurerm_virtual_network" "ad_vnet_data" {
  provider            = azurerm.identity_subscription
  name                = var.ad_vnet
  resource_group_name = var.ad_rg
}

resource "azurerm_virtual_network_peering" "peer1" {
  name                      = "peer_avd-terraform_ad"
  resource_group_name       = var.rg_name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.ad_vnet_data.id
}

resource "azurerm_virtual_network_peering" "peer2" {
  # name                      = "peer_ad_avd-${formatdate("YYYYMMMDD-hhmmss", timestamp())}"
  provider                  = azurerm.identity_subscription
  name                      = "peer_ad_avd-terraform"
  resource_group_name       = var.ad_rg
  virtual_network_name      = var.ad_vnet
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}

#Peering with Hub/connectivity VNet (optional) 
#The "provider" block refers to the other subscription defined in provider.tf
data "azurerm_virtual_network" "hub_vnet_data" {
  provider            = azurerm.connectivity_subscription
  name                = var.hub_vnet
  resource_group_name = var.hub_rg
}

resource "azurerm_virtual_network_peering" "peer_hub1" {
  name                      = "peer_avd-terraform_hub"
  resource_group_name       = var.rg_name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub_vnet_data.id
}

resource "azurerm_virtual_network_peering" "peer_hub2" {
  # name                      = "peer_hub_avd-${formatdate("YYYYMMMDD-hhmmss", timestamp())}"
  provider                  = azurerm.connectivity_subscription
  name                      = "peer_hub_avd-terraform"
  resource_group_name       = var.hub_rg
  virtual_network_name      = var.hub_vnet
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}
