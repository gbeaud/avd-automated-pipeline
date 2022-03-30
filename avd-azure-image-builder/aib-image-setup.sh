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

############ Variables definitions

# Define the resource group's name
imageResourceGroup=rg-imagebuilder-demo-westeu-01
# imageResourceGroup=rg-imagebuilder-weu-2
# Datacenter location
location=westeurope
# Additional region to replicate the image to (optional)
#additionalregion=eastus
# Run output name 
#runOutputName=aibWindows
runOutputName=aib-windows-image

# Name of the new image template
# To keep a version control over templates, it can be named with date and time
# templateName=image-template-$( date '+%F-%H%M%S' )
templateName=it-win11-multi-session-latest
# Name of the image to be created
# imageName=img-win11-multi-session-latest-2
imageName=img-win11-multi-session-latest

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
imageRoleDefName="Azure Image Builder Image Definition"

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

curl https://raw.githubusercontent.com/gbeaud/avd-automated-pipeline/main/avd-azure-image-builder/StandardTemplateWin.json -o temporaryImageTemplateWin.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" temporaryImageTemplateWin.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" temporaryImageTemplateWin.json
sed -i -e "s/<region>/$location/g" temporaryImageTemplateWin.json
sed -i -e "s/<imageName>/$imageName/g" temporaryImageTemplateWin.json
sed -i -e "s/<runOutputName>/$runOutputName/g" temporaryImageTemplateWin.json
sed -i -e "s%<imgBuilderId>%$imgBuilderId%g" temporaryImageTemplateWin.json

echo Template JSON file was created

######################## Create the image template

# Deletes the previous template
# az image builder delete \
# --name $templateName \
# --resource-group $imageResourceGroup

# Submit the image configuration to the VM Image Builder service
# WARNING: there may be a line break at the bottom of the JSON file causing a "LinkedInvalidPropertyId" error. Make sure the file is well formatted! The standard file should not be modified; ref to the original file: https://raw.githubusercontent.com/azure/azvmimagebuilder/master/quickquickstarts/0_Creating_a_Custom_Windows_Managed_Image/temporaryImageTemplateWin.json
az resource create \
--resource-group $imageResourceGroup \
--resource-type Microsoft.VirtualMachineImages/imageTemplates \
--properties @temporaryImageTemplateWin.json \
--is-full-object \
--name $templateName

######################## Builds the image

# Ensures there is no previous image with the same name
# az image delete \
# --name $imageName \
# --resource-group $imageResourceGroup

# Builds the image (This may take about 15-20 minutes)
az resource invoke-action \
--resource-group $imageResourceGroup \
--resource-type Microsoft.VirtualMachineImages/imageTemplates \
--name $templateName \
--action Run

######################## Delete the image template (optional) 

# When creating an image template, in the background, image builder also creates a staging resource group in your subscription. This resource group is used for the image build. It's in the format: IT_<DestinationResourceGroup>_<TemplateName>.

# Do not delete the staging resource group directly. Delete the image template artifact, this will cause the staging resource group to be deleted.

# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-powershell

# To keep a versioning/history of image templates, remove the below command.

# az image builder delete \
# --name $templateName \
# --resource-group $imageResourceGroup