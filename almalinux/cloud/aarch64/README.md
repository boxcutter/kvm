# AlmaLinux OS Generic Cloud (Cloud-init) images

https://wiki.almalinux.org/cloud/Generic-cloud.html#download-images

https://github.com/AlmaLinux/cloud-images

## AlmaLinux 9

```
cd almalinux/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file almalinux-9-aarch64.pkrvars.hcl \
  almalinux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-almalinux-9-aarch64/almalinux-9-aarch64.qcow2 \
    /var/lib/libvirt/images/almalinux-9-aarch64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/almalinux-9-aarch64.qcow2 \
    32G
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
  --os-variant almalinux9 \
  --disk /var/lib/libvirt/images/almalinux-9-aarch64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console almalinux-9

# login with packer user
```

```
$ virsh shutdown almalinux-9
$ virsh undefine almalinux-9 --nvram --remove-all-storage
```
