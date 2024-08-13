```
$ curl -LO http://cloud-images.ubuntu.com/jammy/current/SHA256SUMS
$ curl -LO http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

$ qemu-img info jammy-server-cloudimg-amd64.img 
image: jammy-server-cloudimg-amd64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 622 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    jammy-server-cloudimg-amd64.img \
    /var/lib/libvirt/images/ubuntu-server-2204.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2204.qcow2 \
    32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: ubuntu-server-2204
local-hostname: ubuntu-server-2204
EOF

cat >user-data <<EOF
#cloud-config
password: superseekret
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
    -output ubuntu-server-2204-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp ubuntu-server-2204-cloud-init.img \
  /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2204 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2204.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2204

virt-viewer ubuntu-server-2204

# login with ubuntu user

$ cloud-init status
status: done

# Verify networking is working
$ ip -br a

# Check to make sure cloud-init is greater than 23.4
$ cloud-init --version
/usr/bin/cloud-init 24.1.3-0ubuntu1~22.04.5

# If networking isn't correct, regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ cloud-init status
status: disabled

$ sudo shutdown -h now

$ virsh domblklist ubuntu-server-2204
 Target   Source
-------------------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-server-2204.qcow2
 sda      /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso
 
$ virsh change-media ubuntu-server-2204 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh snapshot-create-as --domain ubuntu-server-2204 --name clean --description "Initial install"
$ virsh snapshot-list ubuntu-server-2204
$ virsh snapshot-revert ubuntu-server-2204 clean
$ virsh snapshot-delete ubuntu-server-2204 clean

$ virsh shutdown ubuntu-server-2204
$ virsh undefine ubuntu-server-2204 --nvram --remove-all-storage
```
