# Libvirt cloud images

```
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

$ qemu-img info jammy-server-cloudimg-amd64.img 
image: jammy-server-cloudimg-amd64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 620 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16

sudo mkdir -p /var/lib/libvirt/images/ubuntu-server-2204
sudo qemu-img convert -f qcow2 -O qcow2 jammy-server-cloudimg-amd64.img /var/lib/libvirt/images/ubuntu-server-2204/root-disk.qcow2
sudo qemu-img resize -f qcow2 /var/lib/libvirt/images/ubuntu-server-2204/root-disk.qcow2 32G
```

```
touch network-config
touch meta-data
cat >user-data <<EOF
#cloud-config
password: password
chpasswd:
  expire: False
ssh_pwauth: True
EOF
```

```
sudo apt-get update
sudo apt-get install genisoimage
#     -input-charset utf-8 \
genisoimage \
    -output seed.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp seed.img /var/lib/libvirt/images/ubuntu-server-2204/seed.iso
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2204 \
  --boot uefi \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2204/root-disk.qcow2,bus=virtio \
  --disk /var/lib/libvirt/images/ubuntu-server-2204/seed.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virt-viewer ubuntu-server-2204

$ virsh domblklist ubuntu-server-2204
 Target   Source
----------------------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-server-2204/root-disk.qcow2
 sda      /var/lib/libvirt/images/ubuntu-server-2204/seed.iso

$ virsh change-media ubuntu-server-2204 sda --eject
Successfully ejected media.
```

```
virt-install \
  --name ubuntu-server-2204 \
  --memory 1024 \
  --noreboot \
  --os-variant detect=on,name=ubuntujammy \
  --disk=size=10,backing_store="$(pwd)/jammy-server-cloudimg-amd64.img" \
  --cloud-init user-data="$(pwd)/user-data,meta-data=$(pwd)/meta-data,network-config=$(pwd)/network-config"
```

References:

https://blog.programster.org/create-ubuntu-22-kvm-guest-from-cloud-image

qemu-img Backing Files: A Poor Man's Sanpshot/Rollback: https://dustymabe.com/2015/01/11/qemu-img-backing-files-a-poor-mans-snapshotrollback/

QCOW2 backing files & overlays: https://kashyapc.fedorapeople.org/virt/lc-2012/snapshots-handout.html
