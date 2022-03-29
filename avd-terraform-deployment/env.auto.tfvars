#This file contains ENVIRONMENT-SPECIFIC variables. In the variables.tf, we can specify static/generic values, while in this env.tfvars file, we will specify the concrete values for a specific deployment.

#The variables defined in this file OVERRIDE the ones in variables.tf 

# Basics
deploy_location = "west europe"
deployment_name = "avd-terraform-demo-westeu-01"
rg_name         = "rg-avd-terraform-demo-westeu-01"

#Active Directory variables
ad_rg          = "rg-domain-controler-westeurope"
ad_vnet        = "adVNET"
dns_servers    = ["10.0.0.4"]
aad_group_name = "AVD Users (Terraform)"
domain_name    = "AZUREVIRTUALDESKTOPDEMO.LOCAL"

#Hub/connectivity VNet variables (optional, this will create a network peering with hub vnet)
hub_rg   = "rg-hub-connectivity-prod-westeu"
hub_vnet = "vnet-hub-connectivity-prod-westeu"

#Network
vnet_range   = ["10.20.0.0/16"]
subnet_range = ["10.20.0.0/24"]

#Storage

#Hosts
#Number of hosts to deploy
rdsh_count = 1

#Reference to custom VM image
# image_name = "img-win11-multi-session-latest"
# image_resource_group = "rg-imagebuilder-test-westeu-01"
image_name           = "img-win11-multi-session-latest-2"
image_resource_group = "rg-imagebuilder-weu-2"

#AVD artifacts
# workspace = "ws-${var.deployment_name}"
# hostpool  = "hp-avd-terraform-test-westeu-01"
prefix = "avd-terraform"

#Users
avd_users = [
  "demouser@M365x389859.onmicrosoft.com",
  "admin@M365x389859.onmicrosoft.com",
  "user2@M365x389859.onmicrosoft.com"
]

#Credentials used to domain join the VMs (the domain user should be part of the "Domain Admins" group in AD, otherwise the number of VMs allowed to be domain joined is 10).
# Passwords are stored on GitHub Secrets but can also be passed when running locally with: terraform plan -out terraform_azure.tfplan -var="domain_password=XYZ" -var="local_admin_password=ABC"
domain_user_upn = "domainadmin"
#Credentials for local admin on the computer
local_admin_username = "demouser"
