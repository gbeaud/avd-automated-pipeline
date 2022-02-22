Guillaume's notes:
- To store Terraform's state file in a storage account, you need to create a storage account and give the service principal the right access (follow this tutorial: https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=powershell)
- The reference to this storage account is in the "backend" block in the "provider.tf" file. To store the state locally, simply remove the "backend" block. (Warning: this will prevent you from deploying from a stateless environment such as GitHub Actions while preserving the state).


## Terraform for Azure Virtual Desktop 

The purpose of this repository is to demonstrate using Terraform to deploy a simple Azure Virtual Desktop environment. For Classic Azure Virtual Desktop click [here](https://github.com/Azure/RDS-Templates/tree/master/wvd-sh/terraform-azurerm-windowsvirtualdesktop).

## Tutorial

This tutorial explains the end-to-end deployment of this project: https://techcommunity.microsoft.com/t5/azure-virtual-desktop/arm-avd-with-terraform/m-p/2639806

## Requirements and limitations 
* Ensure that you meet the [requirements for Azure Virtual Desktop](https://docs.microsoft.com/en-us/azure/virtual-desktop/overview#requirements) 
* Terraform must be installed and configured as outlined [here](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell)
* Active Directory already in place in this example, we are using AD in it’s own VNet.  
* Users in AAD that will be given access to AVD
* This demo does not support Azure ADDS only deployment
* Destroy could produce errors deleting subnet due to resources associated. Manually delete resources within the subnet before running destroy

## Components

* Azure Virtual Desktop Environment 
* Networking Infrastructure 
* Session Hosts 
* Profile Storage 
* Role Based Access Control 

## Features

This directory contains the various components for building out Azure Virtual Desktop.
* `main.tf`  
	deploys a new workspace, hostpool, application group with associations
* `networking.tf`  
	 deploys a new vnet, subnet, nsg and peering to AD vnet
* `host.tf`  
	deploys new session host from the marketplace build and join to domain
* `afstorage.tf`  
	deploys Azure Files storage for profiles and creates file share with RBAC permissions for the users group ([NTFS permissions will need to be configured](https://docs.microsoft.com/en-us/azure/virtual-desktop/create-file-share))
* `rbac.tf`  
	deploys rbac assignment for the users group 
* `variables.tf`  
	Input variables 
* `defaults.tfvars`  
	 declares the actual input values (keep security in mind if you are putting confidential data)
* `provider.tf`  
	Azure RM and Azure AD provider configuation
* `outputs.tf`
	defines the outputs that will be displayed on deployment
* `netappstorage.tf`  
	as an alternate to Azure Files storage this deploys NetApp Files storage for profiles in a dedicated subnet (access needs to be granted to the ANF service) [Set up Azure NetApp Files](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-quickstart-set-up-account-create-volumes?tabs=azure-portal)

## Varialble Inputs

| Name | Description | Default |
|:---|:---|:---|
| `rg_name` | Name of the Resource Group in which to deploy these resources | `AVD-TF` |
| `deploy_location` | Region in which to deploy these resources | - |
| `hostpool` | Name of the Azure Virtual Desktop host pool | `AVD-TF-HP` |
| `ad_vnet` | Name of domain controller VNet | - |
| `dns_servers` | Custom DNS configuration | - |
| `vnet_range` | Address range for deployment VNet | - |
| `subnet_range` | Address range for session host subnet | - |
| `avd_users` | The resource group for AD VM | `[]` |
| `aad_group_name` | Azure Active Directory Group for AVD users | - |
| `rdsh_count` | Number of AVD machines to deploy | 2 |
| `prefix` | Prefix of the name of the AVD machine(s) | - |
| `domain_name` | Name of the domain to join | - |
| `domain_user_upn` | Username for domain join (do not include domain name as this is appended | - |
| `domain_password` | Password of the user to authenticate with the domain | - |
| `vm_size` | Size of the machine to deploy | `Standard_DS2_v2` |
| `ou_path` | The ou path for AD | `""` |
| `local_admin_username` | The local admin username for the VM | - |
| `local_admin_password` | The local admin password for the VM | - |
| `netapp_acct_name` | The NetApp account name | `AVD_NetApp` |
| `netapp_pool_name` | The NetApp pool name | `AVD_NetApp_pool` |
| `netapp_volume_name` | The NetApp volume name | `AVD_NetApp_volume` |
| `netapp_smb_name` | The NetApp smb name | `AVDNetApp` |
| `netapp_volume_path` | The NetApp volume path | `AVDNetAppVolume` |
| `netapp_subnet_name` | The NetApp subnet name | `NetAppSubnet` |
| `netapp_address` | The Address range for NetApp Subnet | - |

## Deploy
If you’ve not previously setup terraform, check out this article to get it installed [Quickstart - Configure Terraform using Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/developer/terraform/get-started-cloud-shell) 

You can review our sample configuration video here

Once Terraform is setup and you have created your Terraform templates, the first step is to initialize Terraform. This step ensures that Terraform has all the prerequisites to build your template in Azure. 

```
terraform init
```

The next step is to have Terraform review and validate the template. An execution plan is generated and stored in the file specified by the -out parameter. 

We also need to pass our variable definitions file during the plan.   We can either load it automatically by renaming env.tfvars as terraform.tfvars OR env.auto.tfvars, in which case we will use the following to create the execution plan: 

```bash
terraform plan -out terraform_azure.tfplan
```

When you're ready to build the infrastructure in Azure, apply the execution plan: 

```bash
terraform apply terraform_azure.tfplan
```

## Final Configuration

You’ll notice we didn’t actually configure the session hosts to use our profile storage at any point.  There is an assumption that we are using GPO to manage FSLogix across our host pools as documented here: [Use FSLogix Group Policy Template Files - FSLogix](https://docs.microsoft.com/en-us/fslogix/use-group-policy-templates-ht).  

At a minimum you’ll need to configure the registry keys to enable FSLogix and configure the VHD Location to the NetApp Share URI: [Profile Container registry configuration settings - FSLogix](https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference#enabled) 

## Troubleshooting Terraform deployment 
<details>
<summary>Click to expand</summary>
Terraform deployment can fail in two main categories: 

Issues with Terraform code 
1. [Issues with Desired State Configuration (DSC)](#issues-with-desired-state-configuration-dsc)
2. [Issues with Terraform code](#issues-with-desired-state-configuration-dsc)
 
While it is rare to have issues with the Terraform code it is still possible, however most often errors are due to bad input in variables.tf. 

* If there are errors in the Terraform code, please file a GitHub issue. 
* If there are warning in the Terraform code feel free to ignore or address for your own instance of that code. 
* Using Terraform error messages it's a good starting point towards identifying issues with input variables 
 
### Issues with Desired State Configuration (DSC) 

To troubleshoot this type of issue, navigate to the Azure portal and if needed reset the password on the VM that failed DSC. Once you are able to log in to the VM review the log files in the following two folders: 
</details>

## Additional References
<details>
<summary>Click to expand</summary>

- [Terraform Download](https://www.terraform.io/downloads.html)
- [Visual Code Download](https://code.visualstudio.com/Download)
- [Powershell VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)
- [HashiCorp Terraform VS Code Extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
- [Azure Terraform VS Code Extension Name](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureterraform)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)
- [Configure the Azure Terraform Visual Studio Code extension](https://docs.microsoft.com/en-us/azure/developer/terraform/configure-vs-code-extension-for-terraform)
- [Setup video](https://youtu.be/YmbmpGdhI6w)
</details>