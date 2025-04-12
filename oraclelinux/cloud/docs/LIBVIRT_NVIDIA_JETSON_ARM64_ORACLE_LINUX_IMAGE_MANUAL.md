# Oracle Linux Cloud Images

https://yum.oracle.com/oracle-linux-templates.html

https://blogs.oracle.com/linux/post/a-quick-start-with-the-oracle-linux-templates-for-kvm

```
$ curl -LO https://yum.oracle.com/templates/OracleLinux/OL9/u4/aarch64/OL9U4_aarch64-kvm-cloud-b90.qcow2

$ qemu-img info OL9U4_aarch64-kvm-cloud-b90.qcow2

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    OL9U4_aarch64-kvm-cloud-b90.qcow2 \
    /var/lib/libvirt/images/oracle-linux-9.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/oracle-linux-9.qcow2 \
    32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: oracle-linux-9
local-hostname: oracle-linux-9
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
    -output oracle-linux-9-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp oracle-linux-9-cloud-init.img \
  /var/lib/libvirt/boot/oracle-linux-9-cloud-init.iso
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name oracle-linux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ol9.4 \
  --disk /var/lib/libvirt/images/oracle-linux-9.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/oracle-linux-9-cloud-init.iso,device=cdrom \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console oracle-linux-9

# login with opc user

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

$ virsh domblklist oracle-linux-9
 Target   Source
---------------------------------------------------------------
 vda      /var/lib/libvirt/images/oracle-linux-9.qcow2
 sda      /var/lib/libvirt/boot/oracle-linux-9-cloud-init.iso

$ virsh change-media oracle-linux-9 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/oracle-linux-9-cloud-init.iso

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown oracle-linux-9
$ virsh undefine oracle-linux-9 --nvram --remove-all-storage
```
