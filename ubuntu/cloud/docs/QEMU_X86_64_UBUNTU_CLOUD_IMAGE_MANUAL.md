# QEMU x86 System Ubuntu Cloud Images

## Ubuntu Server 20.04

Download the Ubuntu Cloud Image
```
$ curl -LO https://cloud-images.ubuntu.com/focal/current/SHA256SUMS
$ curl -LO https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

$ qemu-img info focal-server-cloudimg-amd64.img
image: focal-server-cloudimg-amd64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 597 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16

$ qemu-img convert \
    -O qcow2 \
    focal-server-cloudimg-amd64.img \
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
  -drive file=ubuntu-server-2004.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,readonly=on,unit=1,file=/usr/share/OVMF/OVMF_VARS_4M.fd
```

Login to the image

```
ssh ubuntu@localhost -p 2222
```
