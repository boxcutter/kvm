# Libvirt cloud images on Nvidia Jetson

## Download the Ubuntu Cloud Image
```
# JetPack 5.x
curl -LO https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-arm64.img

# JetPack 6.x
curl -LO https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img

$ qemu-img info jammy-server-cloudimg-arm64.img 
image: jammy-server-cloudimg-arm64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 594 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    refcount bits: 16

sudo mkdir -p /var/lib/libvirt/images/ubuntu-server-2204
sudo qemu-img convert -f qcow2 -O qcow2 jammy-server-cloudimg-arm64.img /var/lib/libvirt/images/ubuntu-server-2204/root-disk.qcow2
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
  --os-variant ubuntu20.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2204/root-disk.qcow2,bus=virtio \
  --disk /var/lib/libvirt/images/ubuntu-server-2204/seed.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --debug

$ virsh domblklist ubuntu-server-2204
 Target   Source
----------------------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-server-2204/root-disk.qcow2
 sda      /var/lib/libvirt/images/ubuntu-server-2204/seed.iso

$ virsh change-media ubuntu-server-2204 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/images/ubuntu-server-2204/seed.iso
$ virsh edit ubuntu-server-2204
# remove entry for the seed.iso
<disk type='file' device='cdrom'>
    <driver name='qemu' type='raw'/>
    <source file='/var/lib/libvirt/images/ubuntu-server-2204/seed.iso'/>
    <target dev='sda' bus='scsi'/>
    <readonly/>
    <address type='drive' controller='0' bus='0' target='0' unit='0'/>
</disk>

# disable cloud-init
sudo touch /etc/cloud/cloud-init.disabled
```

## References

Cloud Images with cloud-init Demystified https://packetpushers.net/blog/cloud-init-demystified/

Add nodes to your private cloud using Cloud-init https://opensource.com/article/20/5/create-simple-cloud-init-service-your-homelab
