# This script is run upon image creation and may contain instructions and configurations to be applied to the image
mkdir c:\buildArtifacts
Write-Output "Guillaume's script was here, triggered from GitHub Actions on May 5th"  > c:\buildArtifacts\azureImageBuilder.txt