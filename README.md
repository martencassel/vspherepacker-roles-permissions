### Setup permissions

```powershell

# Import module
Import-Module ./Module.psm1

# List cmdlets
Get-Command -Module Module

# Import all permissions, use whatif
Import-Permissions ./permissions/k8s-batch/k8s-batch-cns.yaml  -WhatIf:$true

# Import them withouth whatif
Import-Permissions ./permissions/k8s-batch/k8s-batch-cns.yaml  -WhatIf:$true


# Check the effect, by filtering by principal
Get-VIPermission -principal "LAB.LOCAL\k8s-batch-cns"

```


### Building CPI images using packer

```bash
cd ~/github.com
git clone https://github.com/kubernetes-sigs/image-builder.git
# Important step, otherwise packer wont find files required.
cd ~/github.com/image-builder/images/capi
```

```bash
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
```

```bash
export PACKER_LOG=10;
export PACKER_FLAGS="--var 'kubernetes_rpm_version=1.26.9' --var 'kubernetes_semver=v1.26.9' --var 'kubernetes_series=v1.26' --var 'kubernetes_deb_version=1.26.9-1.1'" PACKER_VAR_FILES="/tmp/packer.json" 
make build-node-ova-vsphere-ubuntu-2004
```

```bash
export PACKER_LOG=10;
export PACKER_FLAGS="--var 'kubernetes_rpm_version=1.27.16' --var 'kubernetes_semver=v1.27.16' --var 'kubernetes_series=v1.27' --var 'kubernetes_deb_version=1.27.16-1.1'" PACKER_VAR_FILES="/tmp/packer.json"
make build-node-ova-vsphere-ubuntu-2404
```

```sh
export PACKER_LOG=10;
export PACKER_FLAGS="--var 'kubernetes_rpm_version=1.28.12' --var 'kubernetes_semver=v1.28.12' --var 'kubernetes_series=v1.28' --var 'kubernetes_deb_version=1.28.12-1.1'" PACKER_VAR_FILES="/tmp/packer.json"
make build-node-ova-vsphere-ubuntu-2404   
```

```sh
export PACKER_LOG=10
export PACKER_FLAGS="--var 'kubernetes_rpm_version=1.29.7' --var 'kubernetes_semver=v1.29.7' --var 'kubernetes_series=v1.29' --var 'kubernetes_deb_version=1.29.7-1.1'" PACKER_VAR_FILES="/tmp/packer.json"
make build-node-ova-vsphere-ubuntu-2404  
```

```sh
export PACKER_LOG=10
export PACKER_FLAGS="--var 'kubernetes_rpm_version=1.30.3' --var 'kubernetes_semver=v1.30.3' --var 'kubernetes_series=v1.30' --var 'kubernetes_deb_version=1.30.3-1.1'" PACKER_VAR_FILES="/tmp/packer.json"
make build-node-ova-vsphere-ubuntu-2404
```
