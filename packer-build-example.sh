#!/bin/bash

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

 