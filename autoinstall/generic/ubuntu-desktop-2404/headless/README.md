# Preparing the ISO

```
$ curl -LO https://releases.ubuntu.com/noble/ubuntu-24.04.3-desktop-amd64.iso
# curl -LO https://crake-nexus.org.boxcutter.net/repository/ubuntu-releases-proxy/noble/ubuntu-24.04.3-desktop-amd64.iso
$ shasum -a 256 ubuntu-24.04.3-desktop-amd64.iso
faabcf33ae53976d2b8207a001ff32f4e5daae013505ac7188c9ea63988f8328  ubuntu-24.04.3-desktop-amd64.iso

docker pull docker.io/boxcutter/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    --autoinstall autoinstall.yaml \
    --grub grub.cfg \
    --config-root \
    --source ubuntu-24.04.3-desktop-amd64.iso \
    --destination ubuntu-24.04.3-desktop-amd64-autoinstall.iso

# Verify that /autoinstall.yaml exists
$ sudo apt-get update
$ sudo apt-get install genisoimage
$ isoinfo -R -i \
    ubuntu-24.04.3-desktop-amd64-autoinstall.iso -f | grep -i autoinstall
/autoinstall.yaml
```

# Testing the autoinstall headlessly in a VM using VNC

```
sudo cp ubuntu-24.04.3-desktop-amd64-autoinstall.iso \
  /var/lib/libvirt/iso/ubuntu-24.04.3-desktop-amd64-autoinstall.iso

virt-install \
  --connect qemu:///system \
  --name ubuntu-desktop-2404 \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/ubuntu-24.04.3-desktop-amd64-autoinstall.iso \
  --disk pool=default,format=qcow2,bus=virtio,size=60 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
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

virsh destroy ubuntu-desktop-2404
virsh undefine ubuntu-desktop-2404 --nvram --remove-all-storage
```

```
virsh snapshot-create-as \
  --domain ubuntu-desktop-2404 \
  --name clean \
  --description "Initial install"

virsh snapshot-list ubuntu-desktop-2404
virsh snapshot-revert ubuntu-desktop-2404 clean
virsh snapshot-delete ubuntu-desktop-2404 clean

virsh shutdown ubuntu-desktop-2404
virsh shutdown ubuntu-desktop-2404
```
