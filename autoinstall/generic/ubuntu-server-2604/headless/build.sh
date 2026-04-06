#!/bin/bash

set -x

UBUNTU_SERVER_26_04_ISO=ubuntu-26.04-beta-live-server-amd64.iso
UBUNTU_SERVER_26_04_AUTOINSTALL_ISO="${UBUNTU_SERVER_26_04_ISO}-autoinstall.iso"

sudo rm "${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO}"

docker pull docker.io/boxcutter/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    --autoinstall autoinstall.yaml \
    --grub grub.cfg \
    --config-root \
    --source ${UBUNTU_SERVER_26_04_ISO} \
    --destination ${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO}

sudo rm "/var/lib/libvirt/iso/${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO}"
sudo cp  ${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO} \
  /var/lib/libvirt/iso/${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO}

virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2604 \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO} \
  --disk pool=default,format=qcow2,bus=virtio,size=60 \
  --memory 3192 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --network network=host-network,model=virtio \
  --graphics none \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug
