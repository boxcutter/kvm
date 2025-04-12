# QEMU Rocky Linux aarch64

https://rockylinux.org/download

## Rocky Linux 9

Download the AlmaLinux cloud image

```
$ curl -LO https://dl.rockylinux.org/pub/rocky/9/images/aarch64/CHECKSUM
$ curl -LO https://dl.rockylinux.org/pub/rocky/9/images/aarch64/Rocky-9-GenericCloud-Base.latest.aarch64.qcow2

$ qemu-img info Rocky-9-GenericCloud-Base.latest.aarch64.qcow2

$ qemu-img convert \
    -O qcow2 \
    Rocky-9-GenericCloud-Base.latest.aarch64.qcow2 \
    rockylinux-9.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    rockylinux-9.qcow2 32G
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

Create a firmware image

```
# Qemu expects aarch firmware images to be 64M so the firmware
# images can't be used as is, some padding is needed to
# create an image for pflash
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=/usr/share/AAVMF/AAVMF_CODE.fd of=flash0.img conv=notrunc
dd if=/dev/zero of=flash1.img bs=1M count=64
```

Run the VM with QEMU

```
# default user: rocky
qemu-system-aarch64 \
  -name rockylinux-9 \
  -machine virt,accel=kvm,gic-version=3,kernel-irqchip=on \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-gpu-pci \
  -nographic \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=rockylinux-9.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=flash0.img \
  -drive if=pflash,format=raw,unit=1,file=flash1.img
```

Login to the image

```
# rocky / superseekret
ssh cloud-user@localhost -p 2222
```
