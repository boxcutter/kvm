# AlmaLinux OS Generic Cloud (Cloud-init) images

https://wiki.almalinux.org/cloud/Generic-cloud.html#download-images

https://github.com/AlmaLinux/cloud-images

## AlmaLinux 9

Download the AlmaLinux cloud image

```
curl -LO https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/CHECKSUM
curl -LO https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2

$ qemu-img info AlmaLinux-9-GenericCloud-latest.x86_64.qcow2

$ qemu-img convert \
    -O qcow2 \
    AlmaLinux-9-GenericCloud-latest.x86_64.qcow2 \
    almalinux-9.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    almalinux-9.qcow2 32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: almalinux-9
local-hostname: almalinux-9
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
# default user: almalinux
qemu-system-x86_64 \
  -name almalinux-9 \
  -machine virt,accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=almalinux-9.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,readonly=on,unit=1,file=/usr/share/OVMF/OVMF_VARS_4M.fd \
  -display none -serial mon:stdio
```

Login to the image

```
# almalinux / superseekret
ssh cloud-user@localhost -p 2222
```
