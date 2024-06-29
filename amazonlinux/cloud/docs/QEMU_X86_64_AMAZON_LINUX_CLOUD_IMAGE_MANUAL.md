# QEMU Amazon Linux Images

https://docs.aws.amazon.com/linux/al2023/ug/kvm-supported-configurations.html

https://docs.aws.amazon.com/linux/al2023/ug/outside-ec2-download.html

https://cdn.amazonlinux.com/os-images/latest/kvm/

```
curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.5.20240624.0/kvm/SHA256SUMS
curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.5.20240624.0/kvm/al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2
```

## Amazon Linux 2

Download the Amazon Linux 2 cloud image

```
curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.5.20240624.0/kvm/SHA256SUMS
curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.5.20240624.0/kvm/al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2

$ qemu-img info al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2 
image: al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2
file format: qcow2
virtual size: 25 GiB (26843545600 bytes)
disk size: 1.61 GiB
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
    al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2 \
    amazon-linux-2-x86_64.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    amazon-linux-2-x86_64.qcow2 32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: amazon-linux-2
local-hostname: amazon-linux-2
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
# default user: ec2-user
qemu-system-x86_64 \
  -name amazon-linux-2 \
  -machine virt,accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=amazon-linux-2-x86_64.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,readonly=on,unit=1,file=/usr/share/OVMF/OVMF_VARS_4M.fd
```

Login to the image

```
# ec2-user / superseekret
ssh cloud-user@localhost -p 2222
```
