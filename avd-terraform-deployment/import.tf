# Importing the resource group into the state. If working locally, terraform stores the state in a .tfstate file. However if running from GitHub Actions or Azure DevOps, the state is not preserved between runs. Thus the resource group must be explicitely added in the state.


resource "azurerm_resource_group" "rg-avd-terraform-githubactions-westeu-test-01" {}