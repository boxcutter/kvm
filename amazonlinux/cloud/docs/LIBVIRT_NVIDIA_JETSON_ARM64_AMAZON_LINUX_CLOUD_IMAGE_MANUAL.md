# Amazon Linux Images

https://docs.aws.amazon.com/linux/al2023/ug/kvm-supported-configurations.html

https://docs.aws.amazon.com/linux/al2023/ug/outside-ec2-download.html

https://cdn.amazonlinux.com/al2023/os-images/latest/

```
$ curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.7.20250331.0/kvm-arm64/SHA256SUMS
$ curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.7.20250331.0/kvm-arm64/al2023-kvm-2023.7.20250331.0-kernel-6.1-arm64.xfs.gpt.qcow2

$ qemu-img info al2023-kvm-2023.7.20250331.0-kernel-6.1-arm64.xfs.gpt.qcow2

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    al2023-kvm-2023.7.20250331.0-kernel-6.1-arm64.xfs.gpt.qcow2 \
    /var/lib/libvirt/images/amazonlinux-2023.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/amazonlinux-2023.qcow2 \
    32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: amazonlinux-2023
local-hostname: amazonlinux-2023
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
    -output amazonlinux-2023-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp amazonlinux-2023-cloud-init.img \
  /var/lib/libvirt/boot/amazonlinux-2023-cloud-init.iso
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
# Qemu expects aarch firmware images to be 64M so the firmware
# images can't be used as is, some padding is needed to
# create an image for pflash
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=/usr/share/AAVMF/AAVMF_CODE.fd of=flash0.img conv=notrunc
dd if=/dev/zero of=flash1.img bs=1M count=64

#
#
#

dd if=/dev/zero of=amazonlinux-2023_VARS.img bs=1M count=64
```

```
virt-install \
  --connect qemu:///system \
  --name amazonlinux-2023 \
  --boot loader=/usr/share/AAVMF/AAVMF_CODE.fd,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/AAVMF/AAVMF_VARS.fd \
  --memory 4096 \
  --vcpus 2 \
  --os-variant rhel9-unknown \
  --disk /var/lib/libvirt/images/amazonlinux-2023.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/amazonlinux-2023-cloud-init.iso,device=cdrom \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console amazonlinux-2023

# login with ec2-user user

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

$ virsh domblklist amazonlinux-2023
 Target   Source
-----------------------------------------------------------------
 vda      /var/lib/libvirt/images/amazonlinux-2023.qcow2
 sda      /var/lib/libvirt/boot/amazonlinux-2023-cloud-init.iso

$ virsh change-media amazonlinux-2023 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/amazonlinux-2023-cloud-init.iso

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown amazonlinux-2023
$ virsh undefine amazonlinux-2023 --nvram --remove-all-storage
```
