######################## Create a VM from the image (optional, for testing purpose)

# Loads parameters from local, git-ignored config file
source config

# Creates the testing VM
az vm create \
  --resource-group $imageResourceGroup \
  --name vm-aib-image-test-01 \
  --admin-username $user \
  --admin-password $pwd \
  --image $imageName \
  --location $location
  --size Standard_D4s_v3