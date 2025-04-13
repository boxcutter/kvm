# Debian x86_64 cloud images

## Debian 12 UEFI

```
cd debian/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file debian-12-x86_64.pkrvars.hcl \
  debian.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-debian-12-x86_64/debian-12-x86_64.qcow2 \
    /var/lib/libvirt/images/debian-12-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/debian-12-x86_64.qcow2 \
    32G
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name debian-12 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant debian12 \
  --disk /var/lib/libvirt/images/debian-12-x86_64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console debian-12

# login with packer user
```

```
$ virsh shutdown debian-12
$ virsh undefine debian-12 --nvram --remove-all-storage
```

## Debian 12 BIOS

```
cd debian/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file debian-12-bios-x86_64.pkrvars.hcl \
  debian.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-debian-12-bios-x86_64/debian-12-bios-x86_64.qcow2 \
    /var/lib/libvirt/images/debian-12-bios.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/debian-12-bios.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name debian-12-bios \
  --memory 4096 \
  --vcpus 2 \
  --os-variant debian12 \
  --disk /var/lib/libvirt/images/debian-12-bios.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console debian-12-bios

# login with packer user
```

```
$ virsh shutdown debian-12-bios
$ virsh undefine debian-12-bios --nvram --remove-all-storage
```
