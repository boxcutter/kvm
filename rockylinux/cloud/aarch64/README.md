# Rocky Linux Cloud Images

## Rock Linux 9

```
cd rockylinux/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file rockylinux-9-aarch64.pkrvars.hcl \
  rockylinux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-rockylinux-9-aarch64/rockylinux-9-aarch64.qcow2 \
    /var/lib/libvirt/images/rockylinux-9-aarch64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/rockylinux-9-aarch64.qcow2 \
    32G
```

```
osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name rockylinux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant rocky9 \
  --disk /var/lib/libvirt/images/rockylinux-9-aarch64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console rockylinux-9

# login with packer user
```

```
$ virsh shutdown rockylinux-9
$ virsh undefine rockylinux-9 --nvram --remove-all-storage
```

