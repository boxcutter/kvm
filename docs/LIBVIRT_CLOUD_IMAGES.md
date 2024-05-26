# Libvirt cloud images

```
touch network-config
touch meta-data
cat >user-data <<EOF
#cloud-config
password: password
chpasswd:
  expire: False
ssh_pwauth: True
EOF
```

```
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

$ qemu-img info jammy-server-cloudimg-amd64.img 
image: jammy-server-cloudimg-amd64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 620 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16
```

```
virt-install \
  --name cloud-init-001 \
  --memory 4000 \
  --noreboot \
  --os-variant detect=on,name=ubuntujammy \
  --disk=size=10,backing_store="$(pwd)/jammy-server-cloudimg-amd64.img" \
  --cloud-init user-data="$(pwd)/user-data,meta-data=$(pwd)/meta-data,network-config=$(pwd)/network-config"
```
