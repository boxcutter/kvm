# Ubuntu Server 24.04 autoinstall

## Preparing the ISO

```
$ curl -LO \
    https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso
# curl -LO https://crake-nexus.org.boxcutter.net/repository/ubuntu-releases-proxy/noble/ubuntu-24.04.3-live-server-amd64.iso
$ shasum -a 256 ubuntu-24.04.3-live-server-amd64.iso
c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b  ubuntu-24.04.3-live-server-amd64.iso

docker pull docker.io/boxcutter/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    --autoinstall autoinstall.yaml \
    --grub grub.cfg \
    --config-root \
    --source ubuntu-24.04.3-live-server-amd64.iso \
    --destination ubuntu-24.04.3-live-server-amd64-autoinstall.iso

# Verify that the autoinstall is located in root
$ isoinfo -R -i \
    ubuntu-24.04.3-live-server-amd64-autoinstall.iso -f | grep -i autoinstall
/autoinstall.yaml
```

## Testing the autoinstall in a VM

```
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

# To view install. Once it completes it will stop the vm:
$ virsh console ubuntu-server-2404
$ virt-viewer ubuntu-server-2404

# Start the VM again to verify everything looks good
$ virsh start ubuntu-server-2404
$ virsh console ubuntu-server-2404
```

```
virsh snapshot-create-as \
  --domain ubuntu-server-2404 \
  --name clean \
  --description "Initial install"

virsh snapshot-list ubuntu-server-2404
virsh snapshot-revert ubuntu-server-2404
virsh snapshot-delete ubuntu-server-2404

virsh shutdown ubuntu-server-2404
virsh shutdown ubuntu-server-2404
```
```
