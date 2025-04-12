```
$ curl -LO https://cloud.centos.org/centos/10-stream/x86_64/images/CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2.SHA256SUM
$ curl -LO https://cloud.centos.org/centos/10-stream/x86_64/images/CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2

$ qemu-img info CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2 \
    /var/lib/libvirt/images/centos-stream-10.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/centos-stream-10.qcow2 \
    32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: centos-stream-10
local-hostname: centos-stream-10
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
    -output centos-stream-10-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp centos-stream-10-cloud-init.img \
  /var/lib/libvirt/boot/centos-stream-10-cloud-init.iso
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name centos-stream-10 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos-stream9 \
  --disk /var/lib/libvirt/images/centos-stream-10.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/centos-stream-10-cloud-init.iso,device=cdrom \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console centos-stream-10

# login with cloud-user

$ cloud-init status --wait
status: done

# Verify networking is working
$ ip -br a

# If networking isn't correct, regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ cloud-init status
status: disabled

$ sudo shutdown -h now

$ virsh domblklist centos-stream-10
 Target   Source
-----------------------------------------------------------------
 vda      /var/lib/libvirt/images/centos-stream-10.qcow2
 sda      /var/lib/libvirt/boot/centos-stream-10-cloud-init.iso
 
$ virsh change-media centos-stream-10 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/centos-stream-10-cloud-init.iso

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh snapshot-create-as --domain centos-stream-10 --name clean --description "Initial install"
$ virsh snapshot-list centos-stream-10
$ virsh snapshot-revert centos-stream-10 clean
$ virsh snapshot-delete centos-stream-10 clean

$ virsh shutdown centos-stream-10
$ virsh undefine centos-stream-10 --nvram --remove-all-storage
```
