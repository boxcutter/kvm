```
$ curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS
$ curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-arm64.qcow2

$ qemu-img info debian-12-generic-arm64.qcow2 

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    debian-12-generic-arm64.qcow2 \
    /var/lib/libvirt/images/debian-12.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/debian-12.qcow2 \
    32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: debian-12
local-hostname: debian-12
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
    -output debian-12-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp debian-12-cloud-init.img \
  /var/lib/libvirt/boot/debian-12-cloud-init.iso
```

```
virt-install \
  --connect qemu:///system \
  --name debian-12 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant debian12 \
  --disk /var/lib/libvirt/images/debian-12.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/debian-12-cloud-init.iso,device=cdrom \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console debian-12

# login with debian user

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

$ virsh domblklist debian-12
 Target   Source
----------------------------------------------------------
 vda      /var/lib/libvirt/images/debian-12.qcow2
 sda      /var/lib/libvirt/boot/debian-12-cloud-init.iso

$ virsh change-media debian-12 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/debian-12-cloud-init.iso

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown debian-12
$ virsh undefine debian-12 --nvram --remove-all-storage
```
