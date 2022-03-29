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

# Adding reference to identity subscription to use terraform across subscriptions
provider "azurerm" {
  features {}  
  alias           = "identity_subscription"
  subscription_id = "d351604a-5f79-488d-a73e-666707f38f1f"
}