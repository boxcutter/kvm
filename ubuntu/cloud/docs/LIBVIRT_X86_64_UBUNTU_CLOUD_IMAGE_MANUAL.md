```
$ curl -LO https://cloud-images.ubuntu.com/focal/current/SHA256SUMS
$ curl -LO https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64-disk-kvm.img
$ curl -LO https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
$ qemu-img info focal-server-cloudimg-amd64-disk-kvm.img

$ qemu-img info focal-server-cloudimg-amd64.img 
image: focal-server-cloudimg-amd64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 597 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    focal-server-cloudimg-amd64.img \
    /var/lib/libvirt/images/ubuntu-server-2004.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2004.qcow2 \
    32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: ubuntu-server-2004
local-hostname: ubuntu-server-2004
EOF

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
genisoimage \
    -input-charset utf-8 \
    -output ubuntu-server-2004-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp ubuntu-server-2004-cloud-init.img \
  /var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2004 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2004.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2004

virt-viewer ubuntu-server-2204

# login with ubuntu user
$ cloud-init status
status: data

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ sudo shutdown -h now

$ virsh domblklist ubuntu-server-2004
 Target   Source
-------------------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-server-2004.qcow2
 sda      /var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso

$ virsh change-media ubuntu-server-2004 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso
$ virsh edit ubuntu-server-2004
# remove entry for the cloud-init.iso
<!--
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='/var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
-->

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown ubuntu-server-2004
$ virsh undefine ubuntu-server-2004 --nvram --remove-all-storage
```
