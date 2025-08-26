#!/usr/bin/env bash

sudo systemctl stop incus.service
sudo btrfs property set /var/lib/incus/storage-pools/*/images/* ro false
sudo rm -rf /var/lib/incus /var/lib/lxc /var/lib/lxcfs /var/lib/lxd
sudo ip link delete incusbr0 type bridge


sudo mkdir /var/lib/incus
sudo systemctl start incus.service
sleep 3
sudo incus admin init --dump
sudo incus admin init --auto --network-address=$TAILSCALE_IP --network-port=13512
sudo incus admin init --dump
