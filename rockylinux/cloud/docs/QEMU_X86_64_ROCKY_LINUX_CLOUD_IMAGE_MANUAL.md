# QEMU Rocky Linux x86_64

https://rockylinux.org/download

```
curl -LO https://dl.rockylinux.org/pub/rocky/9/images/x86_64/CHECKSUM
curl -LO https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
```

## Rocky Linux 9

Download the AlmaLinux cloud image

```
curl -LO https://dl.rockylinux.org/pub/rocky/9/images/x86_64/CHECKSUM
curl -LO https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2

$ qemu-img info Rocky-9-GenericCloud-Base.latest.x86_64.qcow2 
image: Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
file format: qcow2
virtual size: 10 GiB (10737418240 bytes)
disk size: 581 MiB
cluster_size: 65536
Format specific information:
    compat: 1.1
    compression type: zlib
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
    extended l2: false

$ qemu-img convert \
    -O qcow2 \
    Rocky-9-GenericCloud-Base.latest.x86_64.qcow2 \
    rockylinux-9-x86_64.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    rockylinux-9-x86_64.qcow2 32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: rockylinux-9
local-hostname: rockyinux-9
EOF

cat <<EOF > user-data
#cloud-config
password: superseekret
chpasswd:
  expire: False
ssh_pwauth: True
EOF
```

Create the cloud-init ISO

```
sudo apt-get update
sudo apt-get install genisoimage
genisoimage \
    -input-charset utf-8 \
    -output cloud-init.iso \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
```

Run the VM with QEMU

```
# default user: rocky
qemu-system-x86_64 \
  -name rockylinux-9 \
  -machine virt,accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=rockylinux-9-x86_64.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,readonly=on,unit=1,file=/usr/share/OVMF/OVMF_VARS_4M.fd
```

Login to the image

```
# rocky / superseekret
ssh cloud-user@localhost -p 2222
```
