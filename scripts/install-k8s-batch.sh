#!/bin/bash

# CAPV version =  v1.11.0
# CAPI imagebuilder OVA:  ubuntu-2404-kube-v1.31.0
# Cluster yaml file: ../yaml/k8s-batch-ubuntu-2404-kube-v1.31.0.yaml

# > cat ~/.cluster-api/clusterctl.yaml

# ## -- Controller settings -- ##
# VSPHERE_USERNAME: "Administrator@vcsa.lab.local"
# VSPHERE_PASSWORD: "L1linux12345!@"

# ## -- Required workload cluster default settings -- ##
# VSPHERE_SERVER: "vcsa.lab.local"
# VSPHERE_DATACENTER: "Datacenter"
# VSPHERE_DATASTORE: "datastore1"
# VSPHERE_NETWORK: "VM Network"
# VSPHERE_RESOURCE_POOL: "Resources"
# VSPHERE_FOLDER: "vm"
# VSPHERE_TEMPLATE: "ubuntu-2404-kube-v1.31.0"
# CONTROL_PLANE_ENDPOINT_IP: "192.168.3.100"   # the IP that kube-vip is going to use as a control plane endpoint
# VIP_NETWORK_INTERFACE: "eth0"              # the network interface that kube-vip is going to use to bind the VIP
# VSPHERE_TLS_THUMBPRINT: "8A:57:2D:92:CC:A4:D2:C2:F8:15:70:0E:2F:D1:69:9B:0F:71:44:F8"
# EXP_CLUSTER_RESOURCE_SET: "true"
# VSPHERE_SSH_AUTHORIZED_KEY: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7VrG7IGHsnWR/yKkveoyUW0OCAcOnapDAThqQ7C34OgyYNuCtvAfgGzU4hr+jDa3IKTe3MvzMTaj76az06C8OhP8p7beIwCk8YpjnoK80LAERIErpcAGO001Njk7g9pqKOZLneqSt74CPCJINiv0S7F3k0SDTx3r8Ay8ra/c5w/3wiEyFksZCTcFCy/OcwlqqqFxUFjARtRn6kuK97wRx8+UClBYRkLShT8S4bR5hrikBHDyPRunxqG2QbpZcGmDdfnSXLKhpRBUdnzMr9+kk80VobR4aYPBeO8gWSAyWwM1O13N2LsVGH02fUuPeWICaLNlIRybf8g6UU9nhf5DxTGjEOXcZoErhatzCr5UyVpdLlh63hjUSHRLwSR/E5VO6vrvpDxJYfIdSHq77h+6eNfc5iH6rgXN8HodkEaKNMaki+wPhwS6XW3tUHKS3zmDNdIFW5ChYPJ5gilB+BS/gIAluztfcqUSg0ULYm1ePzHrvZ5bzwNXr58V4to/CqGc= marten@PSE-C3DBVT3"
# VSPHERE_STORAGE_POLICY: ""
# CPI_IMAGE_K8S_VERSION: "v1.31.0"

# ## -- Kubernetes Version -- ##
# KUBERNETES_VERSION: "v1.31.0"
# NAMESPACE: "cluster-1"


kubectl create ns k8s-batch

# Install
kubectl apply -f ../yaml/k8s-batch-ubuntu-2404-kube-v1.31.0.yaml

# Get cluster
kubectl get cluster -A

# Get kubeconfig
rm -f /tmp/k8s-batch-kubeconfig||true
kubectl get secret/k8s-batch-kubeconfig -n k8s-batch -o json \
  | jq -r .data.value \
  | base64 --decode \
  > /tmp/k8s-batch-kubeconfig

# List pods
KUBECONFIG=/tmp/k8s-batch-kubeconfig kubectl get po -A

# Install calico. CALICO_IPV4POOL_CIDR = 10.0.0.0/16.
KUBECONFIG=/tmp/k8s-batch-kubeconfig kubectl apply -f ../yaml/calico.yaml

KUBECONFIG=/tmp/k8s-batch-kubeconfig kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# List pods
KUBECONFIG=/tmp/k8s-batch-kubeconfig kubectl get po -A

# Import storageclass
KUBECONFIG=/tmp/k8s-batch-kubeconfig kubectl apply -f ../yaml/example-sc.yaml

# Apply PVC
KUBECONFIG=/tmp/k8s-batch-kubeconfig  kubectl apply -f ../yaml/example-pvc.yaml

KUBECONFIG=/tmp/k8s-batch-kubeconfig  kubectl get pvc


# Delete cluster
rm -f /tmp/kind-kubeconfig||true
kind get kubeconfig -n mgmt-cluster > /tmp/kind-kubeconfig
KUBECONFIG=/tmp/kind-kubeconfig kubectl get node
KUBECONFIG=/tmp/kind-kubeconfig kubectl get cluster -A
KUBECONFIG=/tmp/kind-kubeconfig kubectl delete cluster k8s-batch -n=k8s-batch