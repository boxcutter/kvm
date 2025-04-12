# QEMU Oracle Linux Cloud Images

https://docs.oracle.com/en-us/iaas/oracle-linux/kvm/index.htm#introduction

https://yum.oracle.com/oracle-linux-templates.html

## Oracle Linux 9

Download the Oracle Linux 9 Cloud Image
```
curl -LO https://yum.oracle.com/templates/OracleLinux/OL9/u5/x86_64/OL9U5_x86_64-kvm-b259.qcow2

$ qemu-img info OL9U5_x86_64-kvm-b259.qcow2

$ qemu-img convert \
    -O qcow2 \
    OL9U5_x86_64-kvm-b259.qcow2 \
    oracle-linux-9.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    oracle-linux-9.qcow2 42G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: oracle-linux-9
local-hostname: oracle-linux-9
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
# Default user: cloud-user
# Does not appear to support UEFI
qemu-system-x86_64 \
  -name oracle-linux-9 \
  -machine virt,accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=oracle-linux-9.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -display none -serial mon:stdio
```

Login to the image

```
# cloud-user / superseekret
```
