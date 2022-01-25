#!/bin/bash

#Lists all resource groups
az group list -otable
echo hello from test script

az image builder delete --name hello --resource-group rg-imagebuilder-weu-2

hello from custom branch