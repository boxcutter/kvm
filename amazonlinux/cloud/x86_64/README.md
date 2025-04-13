# Amazon Linux Cloud Images

https://docs.aws.amazon.com/linux/al2023/ug/kvm-supported-configurations.html

Latest Amazon Linux 2 image:
https://cdn.amazonlinux.com/os-images/latest/kvm/

Latest Amazon Linux 2023 image:
https://cdn.amazonlinux.com/al2023/os-images/latest/

https://cdn.amazonlinux.com/os-images/2.0.20240610.1/README.cloud-init

## Amazon Linux 2023

```
cd amazonlinux/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file amazonlinux-2023-x86_64.pkrvars.hcl \
  amazonlinux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-amazonlinux-2023-x86_64/amazonlinux-2023-x86_64.qcow2 \
    /var/lib/libvirt/images/amazonlinux-2023-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/amazonlinux-2023-x86_64.qcow2 \
    32G
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
  --disk /var/lib/libvirt/images/amazonlinux-2023-x86_64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console amazonlinux-2023

# login with packer user
```

```
$ virsh shutdown amazonlinux-2023
$ virsh undefine amazonlinux-2023 --nvram --remove-all-storage
```

## Amazon Linux 2023 - BIOS

```
cd amazonlinux/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file amazonlinux-2023-bios-x86_64.pkrvars.hcl \
  amazonlinux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-amazonlinux-2023-bios-x86_64/amazonlinux-2023-bios-x86_64.qcow2 \
    /var/lib/libvirt/images/amazonlinux-2023-bios-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/amazonlinux-2023-bios-x86_64.qcow2 \
    32G
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name amazonlinux-2023-bios \
  --memory 4096 \
  --vcpus 2 \
  --os-variant rhel9-unknown \
  --disk /var/lib/libvirt/images/amazonlinux-2023-bios-x86_64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console amazonlinux-2023-bios

# login with packer user
```

```
$ virsh shutdown amazonlinux-2023-bios
$ virsh undefine amazonlinux-2023-bios --nvram --remove-all-storage
```

