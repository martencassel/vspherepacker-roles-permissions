#!/bin/env /bin/bash

# Default configuration file path
DEFAULT_CONFIG_FILE="/tmp/packer.json"


# Set default config file if not provided
CONFIG_FILE=${CONFIG_FILE:-$DEFAULT_CONFIG_FILE}

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function chsv_check_version() {
  if [[ $1 =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$ ]]; then
    echo "$1"
  else
    echo ""
  fi
}

function chsv_check_version_ex() {
  if [[ $1 =~ ^v.+$ ]]; then
    chsv_check_version "${1:1}"
  else
    chsv_check_version "${1}"
  fi
}

# Function to build the OVA
build_ova() {
    local config_file=$1
    local kubernetes_version=$2
    local ubuntu_version=$3
    local required_dir="images/capi"
    local expected_repo_url="https://github.com/kubernetes-sigs/image-builder.git"

    # Check required parameters
    if [[ -z "$kubernetes_version" || -z "$ubuntu_version" ]]; then
        echo "Error: Missing required parameters. Usage: build_ova <kubernetes_version> <ubuntu_version>"
        return 1
    fi
  
    # Check if the current directory is the required directory
    if [[ "$(pwd)" != *"$required_dir" ]]; then
        echo "Error: This script must be run from the $required_dir directory of $expected_repo_url"
        return 1
    fi

    # Check if we are in a Git repository by looking for the .git directory
    if [[ ! -d "../../.git" ]]; then
        echo "Error: This script must be run from within the image-builder Git repository of $expected_repo_url."
        return 1
    fi

    # Check if the remote URL matches the expected repository URL
    local repo_url=$(git -C ../../ remote get-url origin 2>/dev/null)
    if [[ "$repo_url" != "$expected_repo_url" ]]; then
        echo "Error: This script must be run from a clone of $expected_repo_url."
        return 1
    fi

    # Check if the configuration file exists
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file $config_file not found."
        return 1
    fi

    CONFIG_FILE=$config_file

    # Load configuration from the JSON file
    local vsphere_address=$(jq -r '.vcenter_server' "$config_file")
    local vsphere_port=443  # Default vSphere port

    # Check DNS resolution for the vSphere address
    if ! nslookup "$vsphere_address" &>/dev/null; then
        echo "Error: DNS resolution failed for $vsphere_address."
        return 1
    fi

    # Check if the vSphere server endpoint responds
    if ! nc -z "$vsphere_address" "$vsphere_port"; then
        echo "Error: vSphere server at $vsphere_address:$vsphere_port is not responding."
        return 1
    fi
 
    # Define variables
    KUBERNETES_VERSION=$kubernetes_version
    KUBERNETES_SEMVER="v${KUBERNETES_VERSION}"
    KUBERNETES_SERIES="v${KUBERNETES_VERSION%.*}"
    KUBERNETES_DEB_VERSION="${KUBERNETES_VERSION}-1.1"

    # Print the variables
    echo "KUBERNETES_VERSION: $KUBERNETES_VERSION"
    echo "KUBERNETES_SEMVER: $KUBERNETES_SEMVER"
    echo "KUBERNETES_SERIES: $KUBERNETES_SERIES"
    echo "KUBERNETES_DEB_VERSION: $KUBERNETES_DEB_VERSION"

    echo "Attempting to Build OVA for Kubernetes $KUBERNETES_VERSION on Ubuntu $ubuntu_version"

    # Show config files json using jq
    echo "Configuration file: $config_file"
    jq . "$config_file"

    echo "Running the make command with the exported variables"
    echo "Do you want to continue? [y/N]"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Exiting..."
        return 1
    fi

    # Run the make command with the exported variables
    PACKER_LOG="$PACKER_LOG" \
    PACKER_FLAGS="--var 'kubernetes_rpm_version=${KUBERNETES_VERSION}' --var 'kubernetes_semver=${KUBERNETES_SEMVER}' --var 'kubernetes_series=${KUBERNETES_SERIES}' --var 'kubernetes_deb_version=${KUBERNETES_DEB_VERSION}'" \
    PACKER_VAR_FILES="$config_file" \
    make build-node-ova-vsphere-ubuntu-${ubuntu_version}
}


function simple_static_test {
    PACKER_LOG=10 \
    PACKER_FLAGS="--var 'kubernetes_rpm_version=v1.31.0' --var 'kubernetes_semver=v1.31.0' --var 'kubernetes_series=v1.31' --var 'kubernetes_deb_version=1.31.0-1.1'" \
    PACKER_VAR_FILES="$HOME/packer.json" \
    make build-node-ova-vsphere-ubuntu-2004
}

# Parse command-line options
while getopts "c:" opt; do
    case $opt in
        c) CONFIG_FILE=$OPTARG ;;
        *) echo "Usage: $0  <config-file-path> <kubernetes_version> <ubuntu_version>" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))


# Main function
function main {
    local config_file=$1
    local kubernetes_version=$2
    local ubuntu_version=$3

    if [[ -z "$kubernetes_version" || -z "$ubuntu_version" ]]; then
        echo "Error: Missing required parameters."
        echo "kubernetes_version: $kubernetes_version"
        echo "ubuntu_version: $ubuntu_version"
        echo "Usage: $0 [-c config_file] <kubernetes_version> <ubuntu_version>"
        exit 1
    fi

    if [[ -z "$config_file" ]]; then
        config_file=$DEFAULT_CONFIG_FILE
    fi

    build_ova "$config_file" "$kubernetes_version" "$ubuntu_version"
}


# Example usage
main "$@"