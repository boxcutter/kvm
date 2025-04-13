# Oracle Linux Cloud Images

## Oracle Linux 9 - UEFI

```
cd oraclelinux/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file oracle-linux-9-x86_64.pkrvars.hcl \
  oracle-linux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-oracle-linux-9-x86_64/oracle-linux-9-x86_64.qcow2 \
    /var/lib/libvirt/images/oracle-linux-9-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/oracle-linux-9-x86_64.qcow2 \
    42G
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name oracle-linux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ol9-unknown \
  --disk /var/lib/libvirt/images/oracle-linux-9-x86_64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console oracle-linux-9

# login with packer user
```

```
$ virsh shutdown oracle-linux-9
$ virsh undefine oracle-linux-9 --nvram --remove-all-storage
```

## Oracle Linux 9 - BIOS

```
cd oraclelinux/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file oracle-linux-9-bios-x86_64.pkrvars.hcl \
  oracle-linux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-oracle-linux-9-bios-x86_64/oracle-linux-9-bios-x86_64.qcow2 \
    /var/lib/libvirt/images/oracle-linux-9-bios-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/oracle-linux-9-bios-x86_64.qcow2 \
    42G
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name oracle-linux-9 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ol9-unknown \
  --disk /var/lib/libvirt/images/oracle-linux-9-bios-x86_64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console oracle-linux-9

# login with packer user
```

```
$ virsh shutdown oracle-linux-9
$ virsh undefine oracle-linux-9 --nvram --remove-all-storage
```
