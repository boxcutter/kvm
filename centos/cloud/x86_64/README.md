# CentOS Cloud Images

## CentOS Stream 10 UEFI virtual firmware

```
cd centos/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-10-x86_64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-10-x86_64/centos-stream-10-x86_64.qcow2 \
    /var/lib/libvirt/images/centos-stream-10.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/centos-stream-10.qcow2 \
    32G
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
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console centos-stream-10

# login with packer user
```

```
$ virsh shutdown centos-stream-10
$ virsh undefine centos-stream-10 --nvram --remove-all-storage
```

## CentOS Stream 10 BIOS virtual firmware

```
cd centos/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-10-bios-x86_64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-10-bios-x86_64/centos-stream-10-bios-x86_64.qcow2 \
    /var/lib/libvirt/images/centos-stream-10-bios.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/centos-stream-10-bios.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name centos-stream-10-bios \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos-stream9 \
  --disk /var/lib/libvirt/images/centos-stream-10-bios.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console centos-stream-10-bios

# login with packer user
```

```
$ virsh shutdown centos-stream-10-bios
$ virsh undefine centos-stream-10-bios --nvram --remove-all-storage
```

## CentOS Stream 9 UEFI virtual firmware

```
cd centos/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-9-x86_64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-9-x86_64/centos-stream-9-x86_64.qcow2 \
    /var/lib/libvirt/images/centos-stream-9.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/centos-stream-9.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name centos-stream-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos-stream9 \
  --disk /var/lib/libvirt/images/centos-stream-9.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console centos-stream-9

# login with packer user
```

```
$ virsh shutdown centos-stream-9
$ virsh undefine centos-stream-9 --nvram --remove-all-storage
```

## CentOS Stream 9 BIOS virtual firmware

```
cd centos/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-9-bios-x86_64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-9-bios-x86_64/centos-stream-9-bios-x86_64.qcow2 \
    /var/lib/libvirt/images/centos-stream-9-bios.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/centos-stream-9-bios.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name centos-stream-9-bios \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos-stream9 \
  --disk /var/lib/libvirt/images/centos-stream-9-bios.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console centos-stream-9-bios

# login with packer user
```

```
$ virsh shutdown centos-stream-9-bios
$ virsh undefine centos-stream-9-bios --nvram --remove-all-storage
```
