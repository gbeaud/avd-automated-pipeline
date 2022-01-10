#!/bin/bash

# This script creates a VM image from configuration files hosted on GitHub
# Link to tutorial: https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder
# This script should be run in cloud shell, not on a local shell due to potential issues when identifying the resource provider for the image template


######################## Register the features

# To use Azure Image Builder, you need to register the feature. Check your registration:

az provider show -n Microsoft.VirtualMachineImages | grep registrationState
az provider show -n Microsoft.KeyVault | grep registrationState
az provider show -n Microsoft.Compute | grep registrationState
az provider show -n Microsoft.Storage | grep registrationState
az provider show -n Microsoft.Network | grep registrationState

# If they do not say registered, run the following:

az provider register -n Microsoft.VirtualMachineImages
az provider register -n Microsoft.Compute
az provider register -n Microsoft.KeyVault
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Network


############ Initial settings

# Define the resource group's name
imageResourceGroup=rg-imagebuilder-weu-2
# Datacenter location
location=westeurope
# Additional region to replicate the image to (optional)
#additionalregion=eastus
# Run output name
runOutputName=aibWindows
# Name of the image to be created
imageName=aibWinImage

subscriptionID=$(az account show --query id --output tsv)

# Create resource group
az group create -n $imageResourceGroup -l $location

############# Create user-assigned managed identity and grant permissions

# Create user assigned identity for image builder to access the storage account where the script is located
#identityName=aibBuiUserId$(date +'%s')
identityName=aibBuiUserId
az identity create -g $imageResourceGroup -n $identityName

# Get identity id
imgBuilderCliId=$(az identity show -g $imageResourceGroup -n $identityName --query clientId -o tsv)

# Get the user identity URI, needed for the template
imgBuilderId=/subscriptions/$subscriptionID/resourcegroups/$imageResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$identityName

# Download preconfigured role definition example
curl https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

#imageRoleDefName="Azure Image Builder Image Def"$(date +'%s')
imageRoleDefName="Azure Image Builder Image Def"

# Update the role definition template with parameters corresponding to this execution environment
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" aibRoleImageCreation.json
sed -i -e "s/Azure Image Builder Service Image Creation Role/$imageRoleDefName/g" aibRoleImageCreation.json

# Create role definitions
az role definition create --role-definition ./aibRoleImageCreation.json

# Grant role definition to the user assigned identity
az role assignment create \
    --assignee $imgBuilderCliId \
    --role "$imageRoleDefName" \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

####################### Download the image configuration template example (here you can put your own GitHub link), and modify the .json file with your own parameters defined above

curl https://raw.githubusercontent.com/gbeaud/avd-automated-pipeline/main/avd-azure-image-builder/StandardTemplateWin.json -o helloImageTemplateWin.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" helloImageTemplateWin.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" helloImageTemplateWin.json
sed -i -e "s/<region>/$location/g" helloImageTemplateWin.json
sed -i -e "s/<imageName>/$imageName/g" helloImageTemplateWin.json
sed -i -e "s/<runOutputName>/$runOutputName/g" helloImageTemplateWin.json
sed -i -e "s%<imgBuilderId>%$imgBuilderId%g" helloImageTemplateWin.json

######################## Create the image template

# Submit the image configuration to the VM Image Builder service
# WARNING: there may be a line break at the bottom of the JSON file causing a "LinkedInvalidPropertyId" error. Make sure the file is well formatted! The standard file should not be modified; ref to the original file: https://raw.githubusercontent.com/azure/azvmimagebuilder/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/helloImageTemplateWin.json
az resource create \
    --resource-group $imageResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    --properties @helloImageTemplateWin.json \
    --is-full-object \
    --name helloImageTemplateWin2

######################## Builds the image

# This may take about 15 minutes
az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     --name templateFromAzureDevOps \
     --action Run