# Ubuntu Server 24.04 autoinstall

## Preparing the ISO

```
$ curl -LO \
    https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso
$ shasum -a 256 ubuntu-24.04.3-live-server-amd64.iso
c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b  ubuntu-24.04.3-live-server-amd64.iso

docker pull docker.io/boxcutter/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    -a autoinstall.yaml \
    -g grub.cfg \
    -s ubuntu-24.04.3-live-server-amd64.iso \
    -d ubuntu-24.04.3-live-server-amd64-autoinstall.iso

# Verify that the autoinstall is located in /nocloud
$ isoinfo -R -i \
    ubuntu-24.04.3-live-server-amd64-autoinstall.iso -f | grep -i nocloud
/nocloud
/nocloud/meta-data
/nocloud/user-data
```

## Testing the autoinstall in a VM

```
sudo cp ubuntu-24.04.3-live-server-amd64-autoinstall.iso \
  /var/lib/libvirt/iso/ubuntu-server-2404-autoinstall.iso

virsh vol-create-as default ubuntu-server-2404.qcow2 50G --format qcow2
# virsh vol-delete --pool default ubuntu-server-2404.qcow2

virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2404 \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/ubuntu-server-2404-autoinstall.iso \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --disk vol=default/ubuntu-server-2404.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug

# To view install. Once it completes it will stop the vm:
$ virsh console ubuntu-server-2404
$ virt-viewer ubuntu-server-2404
```

## If you need additional drivers

```bash
# First try to install the kernel modules package
sudo apt-get update
sudo apt-get install linux-modules-$(uname -r)

# sudo modprobe <kernel_module>

# If that still doesn't work, try installing the full generic kernel image
sudo apt-get install linux-image-generic
# linux-generic-hwe-24.04
# sudo apt install linux-lowlatency
sudo reboot
```
