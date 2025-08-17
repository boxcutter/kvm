# Preparing the ISO

```
$ curl -LO https://releases.ubuntu.com/noble/ubuntu-24.04.3-desktop-amd64.iso
$ shasum -a 256 ubuntu-24.04.3-desktop-amd64.iso
faabcf33ae53976d2b8207a001ff32f4e5daae013505ac7188c9ea63988f8328  ubuntu-24.04.3-desktop-amd64.iso

docker pull docker.io/boxcutter/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    -a autoinstall.yaml \
    -g grub.cfg \
    --config-root \
    -s ubuntu-24.04.3-desktop-amd64.iso \
    -d ubuntu-24.04.3-desktop-autoinstall.iso

$ isoinfo -R -i \
    ubuntu-24.04.3-desktop-autoinstall.iso -f | grep -i autoinstall
/autoinstall.yaml
```

# Testing the autoinstall in a VM

```
sudo cp ubuntu-24.04.3-desktop-autoinstall.iso \
  /var/lib/libvirt/iso/ubuntu-desktop-2404-autoinstall.iso

virsh vol-create-as default ubuntu-desktop-2404.qcow2 50G --format qcow2

virt-install \
  --connect qemu:///system \
  --name ubuntu-desktop-2404 \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/ubuntu-desktop-2404-autoinstall.iso \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --disk vol=default/ubuntu-desktop-2404.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --graphics vnc,listen=0.0.0.0,password=foobar \
  --video qxl \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug

virsh vncdisplay ubuntu-desktop-2404
virsh dumpxml ubuntu-desktop-2404 | grep "graphics type='vnc'"

# vnc to server on port  to complete install
# Get the IP address of the default host interface
ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
# Use a vnc client to connect to `vnc://<host_ip>:5900`
# When the install is complete the VM will be shut down
```
