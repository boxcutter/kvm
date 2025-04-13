# Oracle Linux Cloud Images

https://docs.oracle.com/en-us/iaas/oracle-linux/kvm/index.htm#introduction

https://yum.oracle.com/oracle-linux-templates.html

```
curl -LO https://yum.oracle.com/templates/OracleLinux/OL9/u5/x86_64/OL9U5_x86_64-kvm-b259.qcow2

$ qemu-img info OL9U5_x86_64-kvm-b259.qcow2

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    OL9U5_x86_64-kvm-b259.qcow2 \
    /var/lib/libvirt/images/oraclelinux-9.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/oraclelinux-9.qcow2 \
    42G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: oraclelinux-9
local-hostname: oraclelinux-9
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
    -output oraclelinux-9-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp oraclelinux-9-cloud-init.img \
  /var/lib/libvirt/boot/oraclelinux-9-cloud-init.iso
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os vendor="Oracle America"
```

```
virt-install \
  --connect qemu:///system \
  --name oraclelinux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ol9.4 \
  --disk /var/lib/libvirt/images/oraclelinux-9.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/oraclelinux-9-cloud-init.iso,device=cdrom \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console oraclelinux-9

# login with cloud-user
$ cloud-init status --wait
status: data

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

$ virsh domblklist oraclelinux-9
 Target   Source
--------------------------------------------------------------
 vda      /var/lib/libvirt/images/oraclelinux-9.qcow2
 sda      /var/lib/libvirt/boot/oraclelinux-9-cloud-init.iso

$ virsh change-media oraclelinux-9 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/oraclelinux-9-cloud-init.iso

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown oraclelinux-9
$ virsh undefine oraclelinux-9 --nvram --remove-all-storage
```
