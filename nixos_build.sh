#!/usr/bin/env bash

usage() {
	cat <<-EOT >&2
	Usage: $0 <board>
	supported board: 
	m64
	m3
	m2p
	rpi3
	EOT
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

board=$1

# download board specific configuration.nix
echo "Dowloading NixOS configuration for $board"

NIX_CFG="https://raw.githubusercontent.com/Dangku/mynixos/master/${board}_configuration.nix"
curl --insecure $NIX_CFG --output ${board}_configuration.nix -L

if [ ! -f ${board}_configuration.nix ]; then
    echo "board configuration file not exist"
    exit 1
fi

mv ${board}_configuration.nix /etc/nixos/configuration.nix

# download airapkgs
echo "Dowloading and unpacking airapkgs..."
curl --insecure https://github.com/tuuzdu/airapkgs/archive/nixos-unstable.tar.gz --output airapkgs.tar.gz -L
tar xvf airapkgs.tar.gz

# set swap for build
echo "Enable swap"
fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile

# disable boot for raspberry
#echo "Use fdisk to remove the bootable flag from the FAT32 partition, and set it for the ext4 partition"
#umount /boot && fdisk /dev/mmcblk0

# build
echo "Building..."
nixos-rebuild switch -I nixpkgs=/root/airapkgs-nixos-unstable --cores 4
