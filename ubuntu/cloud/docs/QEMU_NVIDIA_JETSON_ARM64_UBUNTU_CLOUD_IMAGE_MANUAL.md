
Download the Ubuntu Cloud Image
```
$ curl -LO https://cloud-images.ubuntu.com/focal/current/SHA256SUMS
$ curl -LO https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-arm64.img

$ qemu-img info focal-server-cloudimg-arm64.img 
image: focal-server-cloudimg-arm64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 560 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    refcount bits: 16

$ qemu-img convert \
    -O qcow2 \
    focal-server-cloudimg-arm64.img \
    ubuntu-server-2004.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    ubuntu-server-2004.qcow2 32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: ubuntu-server-2004
local-hostname: ubuntu-server-2004
EOF

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
qemu-system-aarch64 \
  -name ubuntu-image \
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
  -drive file=ubuntu-server-2004.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=flash0.img \
  -drive if=pflash,format=raw,unit=1,file=flash1.img

Ctrl-a h: Show help (displays all available commands).
Ctrl-a x: Exit QEMU.
Ctrl-a c: Switch between the monitor and the console.
Ctrl-a s: Send a break signal.
```

Login to the image

```
ssh ubuntu@localhost -p 2222
```
