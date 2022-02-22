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

  # Location of the storage account where the state file should be stored
    backend "azurerm" {
      resource_group_name  = var.tf_state_resource_group_name
      storage_account_name = var.tf_state_storage_account_name
      container_name       = var.tf_state_container_name
      key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
