# QEMU Amazon Linux Images

https://docs.aws.amazon.com/linux/al2023/ug/kvm-supported-configurations.html

https://docs.aws.amazon.com/linux/al2023/ug/outside-ec2-download.html

https://cdn.amazonlinux.com/al2023/os-images/latest/

## Amazon Linux 2

Download the Amazon Linux 2 cloud image

```
curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.7.20250331.0/kvm/SHA256SUMS
curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.7.20250331.0/kvm/al2023-kvm-2023.7.20250331.0-kernel-6.1-x86_64.xfs.gpt.qcow2

$ qemu-img info al2023-kvm-2023.7.20250331.0-kernel-6.1-x86_64.xfs.gpt.qcow2

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    al2023-kvm-2023.7.20250331.0-kernel-6.1-x86_64.xfs.gpt.qcow2 \
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
virt-install \
  --connect qemu:///system \
  --name amazonlinux-2023 \
  --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/OVMF/OVMF_VARS_4M.fd \
  --memory 4096 \
  --vcpus 2 \
  --os-variant rhel9-unknown \
  --disk /var/lib/libvirt/images/amazonlinux-2023.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/amazonlinux-2023-cloud-init.iso,device=cdrom \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console amazonlinux-2023

# login with ec2-user

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
$ virsh snapshot-create-as --domain amazonlinux-2023 --name clean --description "Initial install"
$ virsh snapshot-list amazonlinux-2023
$ virsh snapshot-revert amazonlinux-2023 clean
$ virsh snapshot-delete amazonlinux-2023 clean

$ virsh shutdown amazonlinux-2023
$ virsh undefine amazonlinux-2023 --nvram --remove-all-storage
```
