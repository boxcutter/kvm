# QEMU Amazon Linux Images

https://docs.aws.amazon.com/linux/al2023/ug/kvm-supported-configurations.html

https://docs.aws.amazon.com/linux/al2023/ug/outside-ec2-download.html

https://cdn.amazonlinux.com/al2023/os-images/latest/

## Amazon Linux 2

Download the Amazon Linux 2 cloud image

```
$ curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.7.20250331.0/kvm-arm64/SHA256SUMS
$ curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.7.20250331.0/kvm-arm64/al2023-kvm-2023.7.20250331.0-kernel-6.1-arm64.xfs.gpt.qcow2

$ qemu-img info al2023-kvm-2023.7.20250331.0-kernel-6.1-arm64.xfs.gpt.qcow2

$ qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    al2023-kvm-2023.7.20250331.0-kernel-6.1-arm64.xfs.gpt.qcow2 \
    amazonlinux-2023.qcow2
$ qemu-img resize \
    -f qcow2 \
    amazonlinux-2023.qcow2 \
    32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: amazonlinux-2023
local-hostname: amazonlinux-2023
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
  -output amazonlinux-2023-cloud-init.iso \
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
# login: ec2-user
qemu-system-aarch64 \
  -name amazonlinux-2023 \
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
  -drive file=amazonlinux-2023.qcow2,if=virtio,format=qcow2 \
  -cdrom amazonlinux-2023-cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=flash0.img \
  -drive if=pflash,format=raw,unit=1,file=flash1.img

Ctrl-a h: Show help (displays all available commands).
Ctrl-a x: Exit QEMU.
Ctrl-a c: Switch between the monitor and the console.
Ctrl-a s: Send a break signal.
```

Login to the image

```
# ec2-user / superseekret
ssh cloud-user@localhost -p 2222
```
