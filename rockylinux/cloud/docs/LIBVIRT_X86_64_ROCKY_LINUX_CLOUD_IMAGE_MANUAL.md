# Rocky Linux Cloud Images

https://rockylinux.org/download

```
curl -LO https://dl.rockylinux.org/pub/rocky/9/images/x86_64/CHECKSUM
curl -LO https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2

$ qemu-img info Rocky-9-GenericCloud-Base.latest.x86_64.qcow2

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    Rocky-9-GenericCloud-Base.latest.x86_64.qcow2 \
    /var/lib/libvirt/images/rockylinux-9.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/rockylinux-9.qcow2 \
    32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: rockylinux-9
local-hostname: rockylinux-9
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
    -output rockylinux-9-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp rockylinux-9-cloud-init.img \
  /var/lib/libvirt/boot/rockylinux-9-cloud-init.iso
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name rockylinux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant rocky9 \
  --disk /var/lib/libvirt/images/rockylinux-9.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/rockylinux-9-cloud-init.iso,device=cdrom \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console rockylinux-9

# login with rocky user

# Make sure cloud-init is finished
$ cloud-init status --wait
status: done

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not 
# correct, can regenerate with cloud-init

# Check to make sure cloud-init is greater than 23.4
$ cloud-init --version

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ cloud-init status
status: disabled

$ sudo shutdown -h now

$ virsh domblklist rockylinux-9
 Target   Source
-------------------------------------------------------------
 vda      /var/lib/libvirt/images/rockylinux-9.qcow2
 sda      /var/lib/libvirt/boot/rockylinux-9-cloud-init.iso

$ virsh change-media rockylinux-9 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/rockylinux-9-cloud-init.iso

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh snapshot-create-as --domain rockylinux-9 --name clean --description "Initial install"
$ virsh snapshot-list rockylinux-9
$ virsh snapshot-revert rockylinux-9 clean
$ virsh snapshot-delete rockylinux-9 clean

$ virsh shutdown rockylinux-9
$ virsh undefine rockylinux-9 --nvram --remove-all-storage
```
