### Setup permissions

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

### Simplified

```bash


~/github.com/vsphere-packer-roles/scripts/build-ova.sh ~/github.com/vsphere-packer-roles/config/packer.json 1.31.0 2404


```
 