# Create AVD Resource Group
resource "azurerm_resource_group" "rg" {
  # name     = var.rg_name
  name     = "rg-${var.deployment_name}"
  location = var.deploy_location
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  # name                = var.workspace
  name                = "ws-${var.deployment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.deploy_location
  friendly_name       = "ws-${var.deployment_name}"
  description         = "ws-${var.deployment_name}"
}

resource "time_rotating" "avd_token" {
  rotation_days = 30
}

# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.deploy_location
  # name                     = var.hostpool
  name = "hp-${var.deployment_name}"
  # friendly_name            = var.hostpool
  friendly_name            = "hp-${var.deployment_name}"
  validate_environment     = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;"
  description              = "${var.prefix} Terraform HostPool"
  type                     = "Pooled"
  maximum_sessions_allowed = 16
  load_balancer_type       = "DepthFirst" #[BreadthFirst DepthFirst]

  registration_info {
    expiration_date = time_rotating.avd_token.rotation_rfc3339
  }
}

# Creates a resource for the registration token
resource "azurerm_virtual_desktop_host_pool_registration_info" "registration_info" {
  hostpool_id = azurerm_virtual_desktop_host_pool.hostpool.id
  # Expiration date must be within 30 days
  expiration_date = "2022-04-03T23:40:52Z"
}

# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "dag" {
  resource_group_name = azurerm_resource_group.rg.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  location            = var.deploy_location
  type                = "Desktop"
  name                = "${var.prefix}-dag"
  friendly_name       = "Desktop AppGroup"
  description         = "AVD application group"
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool, azurerm_virtual_desktop_workspace.workspace]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}
