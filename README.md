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


### Building CPI images using packer

```bash 

cd ~/github.com/
git clone https://github.com/kubernetes-sigs/image-builder.git

cd ~/github.com/image-builder/images/capi/

# Create the packer.json file
cat > /tmp/packer.json <<EOF
{
    "vcenter_server":"vcsa.lab.local",
    "insecure_connection": "true",
    "username":"packer",
    "password":"P@ssw0rd!",
    "datastore":"datastore1",
    "datacenter":"Datacenter",
    "resource_pool": "",
    "cluster": "Cluster",
    "network": "Datacenter/network/VM Network",
    "folder": "Kubernetes/Templates"
}
EOF


# Function to build the OVA
build_ova() {
    local kubernetes_version=$1
    local ubuntu_version=$2
    PACKER_LOG=10 PACKER_FLAGS="--var 'kubernetes_rpm_version=${kubernetes_version}' --var 'kubernetes_semver=v${kubernetes_version}' --var 'kubernetes_series=v${kubernetes_version%.*}' --var 'kubernetes_deb_version=${kubernetes_version}-1.1'" PACKER_VAR_FILES="/tmp/packer.json" make build-node-ova-vsphere-ubuntu-${ubuntu_version}
}

# Build OVAs for different Kubernetes versions and Ubuntu versions
build_ova "1.26.9" "2004"
build_ova "1.27.16" "2404"
build_ova "1.28.12" "2404"
build_ova "1.29.7" "2404"
build_ova "1.30.3" "2404"

 

```
