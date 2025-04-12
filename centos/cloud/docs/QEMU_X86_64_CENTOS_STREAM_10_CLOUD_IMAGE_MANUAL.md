# QEMU CentOS Cloud Images

More detailed documentation on cloud-init with RHEL can be found here:
https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_cloud-init_for_rhel_9/configuring-cloud-init_cloud-content#configuring-cloud-init_cloud-content

## CentOS Stream 9 

Download the CentOS Cloud Image
```
$ curl -LO https://cloud.centos.org/centos/10-stream/x86_64/images/CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2.SHA256SUM
$ curl -LO https://cloud.centos.org/centos/10-stream/x86_64/images/CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2

$ qemu-img info CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2

$ qemu-img convert \
    -O qcow2 \
    CentOS-Stream-GenericCloud-x86_64-10-latest.x86_64.qcow2 \
    centos-stream-10.qcow2

# Resize the image
$ qemu-img resize \
    -f qcow2 \
    centos-stream-10.qcow2 32G
```

Create a cloud-init configuration

```
touch network-config

cat >meta-data <<EOF
instance-id: centos-stream-10
local-hostname: centos-stream-10
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
  -name centos-stream-10 \
  -machine virt,accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=centos-stream-10.qcow2,if=virtio,format=qcow2 \
  -cdrom cloud-init.iso \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,readonly=on,unit=1,file=/usr/share/OVMF/OVMF_VARS_4M.fd \
  -display none -serial mon:stdio
```

Login to the image

```
# cloud-user / superseekret
ssh cloud-user@localhost -p 2222
```
