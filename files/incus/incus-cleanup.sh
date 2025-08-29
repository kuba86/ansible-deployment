#!/usr/bin/env bash

sudo systemctl status incus.service
sudo systemctl stop incus.service
sudo btrfs property set /var/lib/incus/storage-pools/default/images/* ro false
sudo rm -rf /var/lib/incus /var/lib/lxc /var/lib/lxcfs /var/lib/lxd
sudo ip link delete incusbr0 type bridge


sudo podman pull ghcr.io/cmspam/incus-docker:latest


sudo mkdir /var/lib/incus
sudo systemctl start incus.service
sleep 3
sudo incus admin init --dump
sudo incus admin init --auto --network-address=$TAILSCALE_IP --network-port=13512
sudo incus admin init --dump


# sudo systemctl stop incus.service
# sudo btrfs property set /var/lib/incus/storage-pools/*/images/* ro false
# sudo rm -rf /var/lib/incus /var/lib/lxc /var/lib/lxcfs /var/lib/lxd
# sudo ip link delete incusbr0 type bridge


sudo incus network create --target nuc02 incusnet0
sudo incus network create --target wyse01 incusnet0
sudo incus network create --target wyse02 incusnet0
sudo incus network create --target wyse03 incusnet0
sudo incus network create --target fedora-kde-xps incusnet0
sudo incus network create incusnet0
