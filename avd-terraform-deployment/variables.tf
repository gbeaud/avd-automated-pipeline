variable "rg_name" {
  type        = string
  default     = "rg-avd-terraform-test-westeu-01"
  description = "Name of the Resource group in which to deploy the AVD resources"
}

variable "deploy_location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be created."
}

variable "workspace" {
  type        = string
  description = "Name of the Azure Virtual Desktop workspace"
  default     = "AVD TF Workspace"
}

variable "hostpool" {
  type        = string
  description = "Name of the Azure Virtual Desktop host pool"
  default     = "AVD-TF-HP"
}

variable "ad_vnet" {
  type        = string
  description = "Name of domain controller vnet"
}

variable "ad_rg" {
  type        = string
  description = "The resource group for AD VM"
}

#Hub/connectivity VNet (optional)
variable "hub_vnet" {
  type        = string
  description = "Name of hub/connectivity vnet"
}

#Hub/connectivity resource group (optional)
variable "hub_rg" {
  type        = string
  description = "The resource group for hub/connectivity VNet"
}

variable "dns_servers" {
  type        = list(string)
  description = "Custom DNS configuration"
}

variable "vnet_range" {
  type        = list(string)
  description = "Address range for deployment VNet"
}
variable "subnet_range" {
  type        = list(string)
  description = "Address range for session host subnet"
}

variable "avd_users" {
  description = "AVD users - Terraform"
  default     = []
}

variable "aad_group_name" {
  type        = string
  description = "Azure Active Directory Group for AVD users"
}

variable "rdsh_count" {
  description = "Number of AVD machines to deploy"
  default     = 2
}

variable "prefix" {
  type        = string
  description = "Prefix of the name of the AVD machine(s)"
}

variable "domain_name" {
  type        = string
  description = "Name of the domain to join"
}

variable "domain_user_upn" {
  type        = string
  description = "Username for domain join (do not include domain name as this is appended)"
}

variable "domain_password" {
  type        = string
  description = "Password of the user to authenticate with the domain"
  sensitive   = true
}

variable "vm_size" {
  description = "Size of the machine to deploy"
  default     = "Standard_DS2_v2"
}

variable "ou_path" {
  default = ""
}

variable "local_admin_username" {
  type        = string
  description = "local admin username"
}

variable "local_admin_password" {
  description = "local admin password"
  sensitive   = true
}


variable "image_name" {
  type        = string
  description = "Name of the custom image to be used"
}

variable "image_resource_group" {
  type        = string
  description = "Resource group where custom image resides"
}

variable "deployment_name" {
  type        = string
  description = "Name of deployment, to be used as suffix to name objects"
}
