# QEMU cloud images on the NVIDIA Jetson Platform

## Install cloud image utils

```
sudo apt-get update
sudo apt-get install cloud-image-utils
```

## Download the Ubuntu Cloud Image

```bash
# JetPack 5.x
curl -LO https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-arm64.img

# JetPack 6.x
curl -LO https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img
```

## Create a cloud-init configuration

Create a `user-data` file
```
cat <<EOF > user-data
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - <your-public-ssh-key>
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
EOF
```

Create an empty `meta-data` files
```
touch meta-data
```

## Create the cloud-init ISO

```
cloud-localds cloud-init.iso user-data meta-data
```

## Create a QCOW2 image from the ubuntu cloud image

```
$ qemu-img info jammy-server-cloudimg-arm64.img 
image: jammy-server-cloudimg-arm64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 594 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    refcount bits: 16

qemu-img convert -O qcow2 jammy-server-cloudimg-arm64.img jammy-server-cloudimg-arm64.qcow2

# Resize the image
qemu-img resize -f qcow2 jammy-server-cloudimg-arm64.qcow2 32G
```

## Create firmware image

```
# Qemu expects aarch firmware images to be 64M so the firmware
# images can't be used as is, some padding is needed to
# create an image for pflash
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=/usr/share/AAVMF/AAVMF_CODE.fd of=flash0.img conv=notrunc
dd if=/dev/zero of=flash1.img bs=1M count=64
```

## Run the VM with QEMU

```
qemu-system-aarch64 \
  -name ubuntu-image \
  -machine virt,accel=kvm,gic-version=3,kernel-irqchip=on \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-gpu-pci \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=jammy-server-cloudimg-arm64.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=flash0.img \
  -drive if=pflash,format=raw,unit=1,file=flash1.img
```

## Login to the image with an ssh key

```
ssh ubuntu@localhost -p 2222
```
