# QEMU CentOS Cloud Images

More detailed documentation on cloud-init with RHEL can be found here:
https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_cloud-init_for_rhel_9/configuring-cloud-init_cloud-content#configuring-cloud-init_cloud-content

## CentOS Stream 9 

Download the CentOS Cloud Image
```
$ curl -LO https://cloud.centos.org/centos/9-stream/aarch64/images/CentOS-Stream-GenericCloud-9-latest.aarch64.qcow2.SHA256SUM
$ curl -LO https://cloud.centos.org/centos/9-stream/aarch64/images/CentOS-Stream-GenericCloud-9-latest.aarch64.qcow2

$ qemu-img info CentOS-Stream-GenericCloud-9-latest.aarch64.qcow2

$ qemu-img convert \
    -O qcow2 \
    CentOS-Stream-GenericCloud-9-latest.aarch64.qcow2 \
    centos-stream-9.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    centos-stream-9.qcow2 32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: centos-stream-9
local-hostname: centos-stream-9
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
# login: cloud-user
qemu-system-aarch64 \
  -name centos-stream-9 \
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
  -drive file=centos-stream-9.qcow2,if=virtio,format=qcow2 \
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
# cloud-user / superseekret
ssh cloud-user@localhost -p 2222
```
