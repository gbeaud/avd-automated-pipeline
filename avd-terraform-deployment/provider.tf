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
    resource_group_name  = "rg-management-prod-westeu-01"
    storage_account_name = "saterraformstate01"
    container_name       = "terraform-state-01"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
