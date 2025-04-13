# CentOS Cloud Images

## CentOS Stream 10

```
cd centos/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-10-aarch64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-10-aarch64/centos-stream-10-aarch64.qcow2 \
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
  --boot loader=/usr/share/AAVMF/AAVMF_CODE.fd,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/AAVMF/AAVMF_VARS.fd \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos-stream9 \
  --disk /var/lib/libvirt/images/centos-stream-10.qcow2,bus=virtio \
  --network network=default,model=virtio \
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

## CentOS Stream 9

```
cd centos/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-9-aarch64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-9-aarch64/centos-stream-9-aarch64.qcow2 \
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
  --boot loader=/usr/share/AAVMF/AAVMF_CODE.fd,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/AAVMF/AAVMF_VARS.fd \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos-stream9 \
  --disk /var/lib/libvirt/images/centos-stream-9.qcow2,bus=virtio \
  --network network=default,model=virtio \
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
