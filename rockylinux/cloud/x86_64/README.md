# Rocky Linux Cloud Images

## Rock Linux 9

```
cd rockylinux/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file rockylinux-9-x86_64.pkrvars.hcl \
  rockylinux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-rockylinux-9-x86_64/rockylinux-9-x86_64.qcow2 \
    /var/lib/libvirt/images/rockylinux-9-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/rockylinux-9-x86_64.qcow2 \
    32G
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name rockylinux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant rocky9 \
  --disk /var/lib/libvirt/images/rockylinux-9-x86_64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
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

