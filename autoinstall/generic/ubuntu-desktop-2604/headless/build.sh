# UBUNTU_DESKTOP_26_04_ISO=ubuntu-26.04-beta-desktop-amd64.iso
UBUNTU_DESKTOP_26_04_ISO=resolute-desktop-amd64.iso
# UBUNTU_DESKTOP_26_04_AUTOINSTALL_ISO=ubuntu-26.04-beta-desktop-amd64-autoinstall.iso
UBUNTU_DESKTOP_26_04_AUTOINSTALL_ISO=resolute-desktop-amd64-autoinstall.iso

sudo rm ${UBUNTU_DESKTOP_26_04_AUTOINSTALL_ISO}

docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    --autoinstall autoinstall.yaml \
    --grub grub.cfg \
    --config-root \
    --source ${UBUNTU_DESKTOP_26_04_ISO} \
    --destination ${UBUNTU_DESKTOP_26_04_AUTOINSTALL_ISO}

sudo rm /var/lib/libvirt/iso/${UBUNTU_DESKTOP_26_04_AUTOINSTALL_ISO}
sudo cp  ${UBUNTU_DESKTOP_26_04_AUTOINSTALL_ISO} \
  /var/lib/libvirt/iso/${UBUNTU_DESKTOP_26_04_AUTOINSTALL_ISO}

virt-install \
  --connect qemu:///system \
  --name ubuntu-desktop-2604 \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/${UBUNTU_DESKTOP_26_04_AUTOINSTALL_ISO} \
  --disk pool=default,format=qcow2,bus=virtio,size=127 \
  --memory 8196 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --network network=host-network,model=virtio \
  --graphics vnc,listen=0.0.0.0,password=foobar \
  --video qxl \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug
