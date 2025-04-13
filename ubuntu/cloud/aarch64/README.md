# Ubuntu aarch64 cloud images

## Ubuntu 24.04 UEFI virtual firmware

```
cd ubuntu/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file ubuntu-24.04-aarch64.pkrvars.hcl \
  ubuntu.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-ubuntu-24.04-aarch64/ubuntu-24.04-aarch64.qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2404.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2404.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2404 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2404.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2404

# login with packer user
```

```
$ virsh shutdown ubuntu-server-2404
$ virsh undefine ubuntu-server-2404 --nvram --remove-all-storage
```

## Ubuntu 22.04 UEFI virtual firmware

```
cd ubuntu/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file ubuntu-22.04-aarch64.pkrvars.hcl \
  ubuntu.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-ubuntu-22.04-aarch64/ubuntu-22.04-aarch64.qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2204.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2204.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2204 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2204.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2204

# login with packer user
```

```
$ virsh shutdown ubuntu-server-2204
$ virsh undefine ubuntu-server-2204 --nvram --remove-all-storage
```

