terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
  }

  # Reference of the storage account where the state file should be stored 
  backend "azurerm" {
    resource_group_name  = "rg-core-services-avd-landing-zone-prod-westeu"
    storage_account_name = "saterraformstate01"
    container_name       = "terraform-state-01"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}
}

# # Adding reference to identity subscription to use terraform across subscriptions
# provider "azurerm" {
#   features {}
#   skip_provider_registration = "true"
#   alias                      = "identity_subscription"
#   subscription_id            = "d351604a-5f79-488d-a73e-666707f38f1f"
# }

# # Adding reference to connectivity/hub subscription to use terraform across subscriptions
# provider "azurerm" {
#   features {}
#   skip_provider_registration = "true"
#   alias                      = "connectivity_subscription"
#   subscription_id            = "6bbb4737-d569-4333-986b-2becd81760e4"
# }

# Adding reference to identity subscription to use terraform across subscriptions
provider "azurerm" {
  features {}
  skip_provider_registration = "true"
  alias                      = "identity_subscription"
  subscription_id            = "${var.IDENTITY_SUBSCRIPTION_ID}"
}

# Adding reference to connectivity/hub subscription to use terraform across subscriptions
provider "azurerm" {
  features {}
  skip_provider_registration = "true"
  alias                      = "connectivity_subscription"
  subscription_id            = "${var.CONNECTIVITY_SUBSCRIPTION_ID}"
}

# Adding reference to connectivity/hub subscription to use terraform across subscriptions
provider "azurerm" {
  features {}
  skip_provider_registration = "true"
  alias                      = "landing_zone_collaboration_subscription"
  subscription_id            = "${var.LANDING_ZONE_COLLABORATION_SUBSCRIPTION_ID}"
}
