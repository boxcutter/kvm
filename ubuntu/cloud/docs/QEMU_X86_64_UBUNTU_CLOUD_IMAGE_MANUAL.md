# QEMU x86 System Ubuntu Cloud Images

## Ubuntu Server 24.04

Download the Ubuntu Cloud Image
```
$ curl -LO https://cloud-images.ubuntu.com/noble/current/SHA256SUMS
$ curl -LO https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

$ qemu-img info noble-server-cloudimg-amd64.img

$ qemu-img convert \
    -O qcow2 \
    noble-server-cloudimg-amd64.img \
    ubuntu-server-2404.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    ubuntu-server-2404.qcow2 32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: ubuntu-server-2404
local-hostname: ubuntu-server-2404
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
  -name ubuntu-image \
  -machine virt,accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=ubuntu-server-2404.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,readonly=on,unit=1,file=/usr/share/OVMF/OVMF_VARS_4M.fd \
  -display none -serial mon:stdio
```

Login to the image

```
ssh ubuntu@localhost -p 2222
```
