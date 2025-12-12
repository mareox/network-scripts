#!/bin/bash

# Exit on any error
set -e

# Function to check if script is running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root" >&2
        exit 1
    fi
}

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="redhat"
    else
        echo "Unable to detect Linux distribution" >&2
        exit 1
    fi
    echo "Detected distribution: $DISTRO"
}

# Function to install NFS client packages
install_nfs_client() {
    echo "Installing NFS client packages..."
    
    case $DISTRO in
        "ubuntu"|"debian")
            apt-get update
            apt-get install -y nfs-common
            ;;
        "fedora"|"rhel"|"centos"|"rocky"|"almalinux")
            dnf install -y nfs-utils
            systemctl enable --now rpcbind
            ;;
        "suse"|"opensuse"*)
            zypper install -y nfs-client
            systemctl enable --now rpcbind
            ;;
        *)
            echo "Unsupported distribution: $DISTRO" >&2
            exit 1
            ;;
    esac
    
    echo "NFS client packages installed successfully"
}

# Function to create the necessary folder
create_folder() {
    local mount_point="/mx-server/backups/BK_vaultwarden"
    
    echo "Creating mount point: $mount_point"
    mkdir -p "$mount_point"
    
    echo "Mount point created successfully"
}

# Function to configure the permanent mount
configure_mount() {
    local fstab_entry="192.168.10.100:/volume1/BACKUPS/BK_vaultwarden /mx-server/backups/BK_vaultwarden nfs defaults 0 0"
    local fstab_file="/etc/fstab"
    
    echo "Configuring permanent mount..."
    
    # Check if the entry already exists
    if grep -q "192.168.10.100:/volume1/BACKUPS/BK_vaultwarden" "$fstab_file"; then
        echo "NFS mount entry already exists in $fstab_file"
    else
        echo "Adding NFS mount entry to $fstab_file"
        echo "$fstab_entry" >> "$fstab_file"
    fi
    
    echo "Permanent mount configured successfully"
}

# Function to test the mount
test_mount() {
    local mount_point="/mx-server/backups/BK_vaultwarden"
    
    echo "Testing NFS mount..."
    
    # First unmount if already mounted
    if mount | grep -q "$mount_point"; then
        umount "$mount_point"
    fi
    
    # Try to mount
    if mount "$mount_point"; then
        echo "NFS mount test successful"
        # Unmount after test
        umount "$mount_point"
    else
        echo "NFS mount test failed! Please check your network and NFS server configuration" >&2
        exit 1
    fi
}

# Main function
main() {
    echo "Starting NFS client setup..."
    
    check_root
    detect_distro
    install_nfs_client
    create_folder
    configure_mount
    test_mount
    
    echo "Setup completed successfully. To mount now, run: mount -a"
    echo "The NFS share will be automatically mounted on next system boot."
}

# Run the script
main