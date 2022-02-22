#This file contains ENVIRONMENT-SPECIFIC variables. In the variables.tf, we can specify static/generic values, while in this env.tfvars file, we will specify the concrete values for a specific deployment.

#The variables defined in this file OVERRIDE the ones in variables.tf

# Basics
deploy_location = "west europe"
rg_name         = "rg-avd-terraform-test-westeu-04"

#Active Directory variables
ad_rg          = "rg-domain-controler-westeurope"
ad_vnet        = "adVNET"
dns_servers    = ["10.0.0.4"]
aad_group_name = "AVD Users"
domain_name    = "AZUREVIRTUALDESKTOPDEMO.LOCAL"

#Hub/connectivity VNet variables (optional, this will create a network peering)
hub_rg   = "rg-hub-connectivity-prod-westeu"
hub_vnet = "vnet-hub-connectivity-prod-westeu-01"

#Network
vnet_range   = ["10.1.4.0/24"]
subnet_range = ["10.1.4.0/24"]

#Storage

#Hosts
#Number of hosts to deploy
rdsh_count = 2

#VM image
# image_name = "img-win11-multi-session-latest"
# image_resource_group = "rg-imagebuilder-test-westeu-01"
image_name = "img-win11-multi-session-latest-2"
image_resource_group = "rg-imagebuilder-weu-2"

#AVD artifacts
workspace = "ws-avd-terraform-test"
hostpool  = "hp-avd-terraform-test"
prefix    = "avd-test"

#Users
avd_users = [
 "demouser@M365x389859.onmicrosoft.com",
 "admin@M365x389859.onmicrosoft.com",
 "user2@M365x389859.onmicrosoft.com"
]

#Credentials used to domain join the VMs (the user should be part of the "Domain Admins" group in AD, otherwise the number of VMs allowed to be domain joined is 10)
domain_user_upn      = "domainadmin"
domain_password      = "Vm-password-123"
#Credentials for local admin on the computer
local_admin_username = "demouser"
local_admin_password = "Vm-password-123"