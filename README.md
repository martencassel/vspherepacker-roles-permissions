### Setup vSphere Roles/Permissions using YAML files

```powershell

# Import module
Import-Module ./Module.psm1

# List cmdlets
Get-Command -Module Module

# Import all permissions, use whatif
Import-Permissions ./permissions/k8s-batch/k8s-batch-cns.yaml  -WhatIf:$true

# Import them withouth whatif
Import-Permissions ./permissions/k8s-batch/k8s-batch-cns.yaml  -WhatIf:$false

# Check the effect, by filtering by principal
Get-VIPermission -principal "LAB.LOCAL\k8s-batch-cns"


# Example update of propagate flag
SetVIPermission `
    -Role "CNS-SEARCH-AND-SPBM" `
    -Name "Datacenter" `
    -ViewType "Datacenter" `
    -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $true

Get-VIPermission -principal "LAB.LOCAL\k8s-batch-cns"

SetVIPermission `
    -Role "CNS-SEARCH-AND-SPBM" `
    -Name "Datacenter" `
    -ViewType "Datacenter" `
    -Principal "LAB.LOCAL\k8s-batch-cns" -Propagate $false


Get-VIPermission -principal "LAB.LOCAL\k8s-batch-cns"

```

### Getting started with CAPI image builds

```bash

# The packer script uses the "packer" account with permission defined using the powershell module

# Make sure that the settings for vsphere packer plugin are correct:
vim  ~/github.com/vsphere-packer-roles/config/packer.json

# Change the working directory to be image-builder directory
cd ~/github.com/image-builder/images/capi/

# Try running the build
~/github.com/vsphere-packer-roles/scripts/build-ova.sh \
    ~/github.com/vsphere-packer-roles/config/packer.json 1.31.0 2404

# Packer log files are availebl in /tmp/packer*
ls -lt /tmp/packer*

```
  
[![asciicast](https://asciinema.org/a/eRSHL768vLB04OyNOKR9FhK0f.svg)](https://asciinema.org/a/eRSHL768vLB04OyNOKR9FhK0f)