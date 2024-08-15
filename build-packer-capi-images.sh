#!/bin/bash

cd ~/github.com/image-builder/images/capi/

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

# k8s 1.26.9, ubuntu-2004
PACKER_LOG=10 PACKER_FLAGS="--var 'kubernetes_rpm_version=1.26.9' --var 'kubernetes_semver=v1.26.9' --var 'kubernetes_series=v1.26' --var 'kubernetes_deb_version=1.26.9-1.1'" PACKER_VAR_FILES="/tmp/packer.json" make build-node-ova-vsphere-ubuntu-2004

# k8s 1.27.16, ubuntu-2404

PACKER_LOG=10 PACKER_FLAGS="--var 'kubernetes_rpm_version=1.27.16' --var 'kubernetes_semver=v1.27.16' --var 'kubernetes_series=v1.27' --var 'kubernetes_deb_version=1.27.16-1.1'" PACKER_VAR_FILES="/tmp/packer.json" make build-node-ova-vsphere-ubuntu-2404

# k8s 1.28.12, ubuntu-2404

PACKER_LOG=10 PACKER_FLAGS="--var 'kubernetes_rpm_version=1.28.12' --var 'kubernetes_semver=v1.28.12' --var 'kubernetes_series=v1.28' --var 'kubernetes_deb_version=1.28.12-1.1'" PACKER_VAR_FILES="/tmp/packer.json" make build-node-ova-vsphere-ubuntu-2404

# k8s 1.29.7, ubuntu-2404

PACKER_LOG=10 PACKER_FLAGS="--var 'kubernetes_rpm_version=1.29.7' --var 'kubernetes_semver=v1.29.7' --var 'kubernetes_series=v1.29' --var 'kubernetes_deb_version=1.29.7-1.1'" PACKER_VAR_FILES="/tmp/packer.json" make build-node-ova-vsphere-ubuntu-2404

# k8s 1.30.3, ubuntu-2404

PACKER_LOG=10 PACKER_FLAGS="--var 'kubernetes_rpm_version=1.30.3' --var 'kubernetes_semver=v1.30.3' --var 'kubernetes_series=v1.30' --var 'kubernetes_deb_version=1.30.3-1.1'" PACKER_VAR_FILES="/tmp/packer.json" make build-node-ova-vsphere-ubuntu-2404

