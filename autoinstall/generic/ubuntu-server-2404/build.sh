#!/bin/bash

set -x

sudo rm ubuntu-24.04.3-live-server-amd64-autoinstall.iso

docker pull docker.io/boxcutter/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    --autoinstall autoinstall.yaml \
    --grub grub.cfg \
    --config-root \
    --source ubuntu-24.04.3-live-server-amd64.iso \
    --destination ubuntu-24.04.3-live-server-amd64-autoinstall.iso

sudo rm /var/lib/libvirt/iso/ubuntu-24.04.3-live-server-amd64-autoinstall.iso
sudo cp ubuntu-24.04.3-live-server-amd64-autoinstall.iso \
  /var/lib/libvirt/iso/ubuntu-24.04.3-live-server-amd64-autoinstall.iso

virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2404 \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/ubuntu-24.04.3-live-server-amd64-autoinstall.iso \
  --disk pool=default,format=qcow2,bus=virtio,size=60 \
  --memory 3192 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --network network=host-network,model=virtio \
  --graphics none \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug
