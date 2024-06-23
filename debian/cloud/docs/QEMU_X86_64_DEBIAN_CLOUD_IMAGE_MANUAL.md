# QEMU Debian Cloud Images

## Debian 12/Bookworm

Download the Debian cloud image

```
$ curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS
$ curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

$ qemu-img info debian-12-generic-amd64.qcow2
image: debian-12-generic-amd64.qcow2
file format: qcow2
virtual size: 2 GiB (2147483648 bytes)
disk size: 424 MiB
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
    debian-12-generic-amd64.qcow2 \
    debian-12.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    debian-12.qcow2 32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: debian-12
local-hostname: debian-12
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
qemu-system-x86_64 \
  -name debian-12 \
  -machine virt,accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=debian-12.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,readonly=on,unit=1,file=/usr/share/OVMF/OVMF_VARS_4M.fd
```

Login to the image

```
# debian / superseekret
ssh cloud-user@localhost -p 2222
```
