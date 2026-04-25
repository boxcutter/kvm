# Ubuntu Server 26.04 autoinstall

## Preparing the ISO

```
$ curl -LO \
    https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso
# curl -LO https://crake-nexus.org.boxcutter.net/repository/ubuntu-releases-prox
y/resolute/SHA256SUMS
# curl -LO https://crake-nexus.org.boxcutter.net/repository/ubuntu-releases-prox
y/26.04/ubuntu-26.04-live-server-amd64.iso

docker pull docker.io/boxcutter/ubuntu-autoinstall
UBUNTU_SERVER_26_04_ISO=ubuntu-26.04-live-server-amd64.iso
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    --autoinstall autoinstall.yaml \
    --grub grub.cfg \
    --config-root \
    --source ${UBUNTU_SERVER_26_04_ISO} \
    --destination ${UBUNTU_SERVER_26_04_ISO}-autoinstall.iso

# Verify that the autoinstall is located in root
$ isoinfo -R -i \
    ${UBUNTU_SERVER_26_04_ISO}-autoinstall.iso -f | grep -i autoinstall
/autoinstall.yaml
```

## Testing the autoinstall in a VM

```
UBUNTU_SERVER_26_04_ISO=ubuntu-26.04-live-server-amd64.iso
UBUNTU_SERVER_26_04_AUTOINSTALL_ISO=ubuntu-26.04-live-server-amd64-autoinstall.iso
sudo cp ${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO} \
  /var/lib/libvirt/iso/${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO}

virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2604 \
  --boot uefi \
  --cdrom  /var/lib/libvirt/iso/${UBUNTU_SERVER_26_04_AUTOINSTALL_ISO} \
  --disk pool=default,format=qcow2,bus=virtio,size=60 \
  --memory 3192 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --network network=host-network,model=virtio \
  --graphics none \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug

# To view install. Once it completes it will stop the vm:
$ virsh console ubuntu-server-2604
$ virt-viewer ubuntu-server-2604

# Start the VM again to verify everything looks good
$ virsh start ubuntu-server-2604
$ virsh console ubuntu-server-2604
```

```
virsh snapshot-create-as \
  --domain ubuntu-server-2604 \
  --name clean \
  --description "Initial install"

virsh snapshot-list ubuntu-server-2604
virsh snapshot-revert ubuntu-server-2604
virsh snapshot-delete ubuntu-server-2604

virsh shutdown ubuntu-server-2604
virsh shutdown ubuntu-server-2604
```
