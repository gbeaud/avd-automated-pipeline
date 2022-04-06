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

############ Cutom variables definitions

imageResourceGroup=rg-imagebuilder-demo-westeu-03
location=westeurope

# Run output name
runOutputName=aib-windows-image
# Name of the new image template
templateName=it-win11-multi-session-latest-03
# Name of the image to be created
imageName=img-win11-multi-session-latest
# Name of compute gallery to share the custom image
computeGalleryName=acg_compute_gallery_avd_demo_westeu_03
# Name of image definition
imageDefinition=image-definition-avd-default

############ Automatic variables and resource creation

subscriptionID=$(az account show --query id --output tsv)

# Create resource group
az group create -n $imageResourceGroup -l $location -t Environment=Demo

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

####################### Publish the image to an Azure Compute Gallery for cross-subscription sharing


# Create a compute gallery
az sig create \
    --gallery-name $computeGalleryName \
    --resource-group $imageResourceGroup \
    --description "Compute gallery for AVD images" \
    --tags Environment=Demo


# Create an image definition (Image definitions create a logical grouping for images. They are used to manage information about the image versions that are created within them.)
# This operation might take a long time depending on the replicate region number.
az sig image-definition create \
    --resource-group $imageResourceGroup \
    --gallery-name $computeGalleryName \
    --gallery-image-definition $imageDefinition \
    --publisher Quorum \
    --offer AVD \
    --sku mySKU \
    --os-type Windows \
    --os-state generalized \
    --hyper-v-generation V2


# Create an image version and add it to the image definition in the shared gallery
# --managed-image is the reference to the image to be added to the gallery
# This step may take a long time to execute
az sig image-version create \
    --resource-group $imageResourceGroup \
    --gallery-image-definition $imageDefinition \
    --gallery-image-version 0.0.1 \
    --gallery-name $computeGalleryName \
    --managed-image $imageName