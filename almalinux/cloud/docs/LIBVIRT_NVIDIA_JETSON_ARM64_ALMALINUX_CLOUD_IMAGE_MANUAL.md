# AlmaLinux OS Generic Cloud (Cloud-init) images

https://wiki.almalinux.org/cloud/Generic-cloud.html#download-images

https://github.com/AlmaLinux/cloud-images

```
$ curl -LO https://repo.almalinux.org/almalinux/9/cloud/aarch64/images/CHECKSUM
$ curl -LO https://repo.almalinux.org/almalinux/9/cloud/aarch64/images/AlmaLinux-9-GenericCloud-latest.aarch64.qcow2

$ qemu-img info AlmaLinux-9-GenericCloud-latest.aarch64.qcow2

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    AlmaLinux-9-GenericCloud-latest.aarch64.qcow2 \
    /var/lib/libvirt/images/almalinux-9.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/almalinux-9.qcow2 \
    32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: almalinux-9
local-hostname: almalinux-9
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
    -output almalinux-9-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp almalinux-9-cloud-init.img \
  /var/lib/libvirt/boot/almalinux-9-cloud-init.iso
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name almalinux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant rocky9 \
  --disk /var/lib/libvirt/images/almalinux-9.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/almalinux-9-cloud-init.iso,device=cdrom \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console almalinux-9

# login with almalinux user

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

$ virsh domblklist almalinux-9
 Target   Source
------------------------------------------------------------
 vda      /var/lib/libvirt/images/almalinux-9.qcow2
 sda      /var/lib/libvirt/boot/almalinux-9-cloud-init.iso

$ virsh change-media almalinux-9 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/almalinux-9-cloud-init.iso

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown almalinux-9
$ virsh undefine almalinux-9 --nvram --remove-all-storage
```
