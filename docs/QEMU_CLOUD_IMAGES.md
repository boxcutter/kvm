# QEMU cloud images

## Install cloud image utils

```
sudo apt-get update
sudo apt-get install cloud-image-utils
```

## Download the Ubuntu Cloud Image

```bash
curl -LO https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

shasum -a 256 noble-server-cloudimg-amd64.img
0cf56a2b23b430c350311dbcb9221b64823a5f7a401b5cf6ab4821f2ffdabe76 *noble-server-cloudimg-amd64.img
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
# Convert the image to QCOW2 format, which supports snapshots
qemu-img convert -O qcow2 noble-server-cloudimg-amd64.img noble-server-cloudimg-amd64.qcow2
# Resize the image
qemu-img resize -f qcow2 noble-server-cloudimg-amd64.qcow2 32G
```

## Run the VM with QEMU booting with UEFI

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
  -drive file=noble-server-cloudimg-amd64.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,readonly=on,unit=1,file=/usr/share/OVMF/OVMF_VARS_4M.fd
```

## Run the VM with QEMU booting with BIOS

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
  -drive file=noble-server-cloudimg-amd64.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso
```

## Login to the image with an ssh key

```
ssh ubuntu@localhost -p 2222
```

## References

[How to run cloud-init locally](https://cloudinit.readthedocs.io/en/latest/howto/run_cloud_init_locally.html)
[Launching Ubuntu Cloud Images with QEMU](https://powersj.io/posts/ubuntu-qemu-cli/)
