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

## Mount cloud image without any special tooling

Install required tools:
```
sudo apt update
sudo apt install qemu-utils
```

If the image is in QCOW2 format, convert it to raw:
```
qemu-img convert -f qcow2 -O raw jammy-server-cloudimg-amd64.img jammy-server-cloudimg-amd64.raw
```

Find the offset of where the partition starts:
```
$ fdisk -l jammy-server-cloudimg-amd64.raw 
Disk jammy-server-cloudimg-amd64.raw: 2.2 GiB, 2361393152 bytes, 4612096 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 00C72DCD-0CD8-440E-824E-C6B53F27E5F1

Device                             Start     End Sectors  Size Type
jammy-server-cloudimg-amd64.raw1  227328 4612062 4384735  2.1G Linux filesystem
jammy-server-cloudimg-amd64.raw14   2048   10239    8192    4M BIOS boot
jammy-server-cloudimg-amd64.raw15  10240  227327  217088  106M EFI System

Partition table entries are not in disk order.

# Offset is the second number times the sector size (usually 512 bytes)
$ echo $((227328 * 512))
116391936

# Mount the image
sudo mkdir /mnt/my_image
sudo mount -o loop,offset=116391936 jammy-server-cloudimg-amd64.raw /mnt/my_image

# Image contents are available as /mnt/my_image

# Unmount the iamge
sudo umount /mnt/my_image
rmdir /mnt/my_image
```

## Mount cloud image with qemu-nbd

```
# Load the nbd module
sudo modprobe nbd
# Verify the nbd module is loaded
$ lsmod | grep nbd
nbd                    65536  0

$ ls /dev/nbd*
/dev/nbd0   /dev/nbd11  /dev/nbd14  /dev/nbd3  /dev/nbd6  /dev/nbd9
/dev/nbd1   /dev/nbd12  /dev/nbd15  /dev/nbd4  /dev/nbd7
/dev/nbd10  /dev/nbd13  /dev/nbd2   /dev/nbd5  /dev/nbd8

# Connect the QCOW2 image as a network block device
sudo qemu-nbd --connect=/dev/nbd0 jammy-server-cloudimg-amd64.img

# Create a mount point directory
sudo mkdir /mnt/my_image

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 2.2 GiB, 2361393152 bytes, 4612096 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 00C72DCD-0CD8-440E-824E-C6B53F27E5F1

Device        Start     End Sectors  Size Type
/dev/nbd0p1  227328 4612062 4384735  2.1G Linux filesystem
/dev/nbd0p14   2048   10239    8192    4M BIOS boot
/dev/nbd0p15  10240  227327  217088  106M EFI System

Partition table entries are not in disk order.

sudo mount /dev/nbd0p1 /mnt/my_image

$ ls /mnt/my_image
bin   dev  home  lib32  libx32      media  opt   root  sbin  srv  tmp  var
boot  etc  lib   lib64  lost+found  mnt    proc  run   snap  sys  usr

# Use chroot jail to execute commands inside of the mounted root filesystem
$ sudo chroot /mnt/my_image
root@sfo2-kvm-playpen-ubuntu2204-desktop:/# ls
bin   dev  home  lib32  libx32      media  opt   root  sbin  srv  tmp  var
boot  etc  lib   lib64  lost+found  mnt    proc  run   snap  sys  usr
root@sfo2-kvm-playpen-ubuntu2204-desktop:/#

# Exit chroot and unmount the image file
$ sudo umount /mnt/mY-image
$ sudo qemu-nbd --disconnect /dev/nbd0
```


#
#
#

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
sudo apt-get update
sudo apt-get install genisoimage
#     -input-charset utf-8 \
genisoimage \
    -output seed.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
```

```
curl -LO https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

```
qemu-system-x86_64 \
  -m 1024 \
  -net nic \
  -net user \
  -hda jammy-server-cloudimg-amd64.img \
  -hdb seed.img
```

```
qemu-system-x86_64 \
  -net nic \
  -net user \
  -machine accel=kvm:tcg \
  -cpu host \
  -m 1024 \
  -hda jammy-server-cloudimg-amd64.img \
  -hdb seed.img
```

```
qemu-system-x86_64 \
  -m 1024 \
  -net nic \
  -net user \
  -machine accel=kvm:tcg \
  -cpu host \
  -hda jammy-server-cloudimg-amd64.img \
  -drive file=seed.img,format=raw,index=1,media=disk \
  -bios /usr/share/OVMF/OVMF_CODE.fd
```

```
# CTRL+A c quit
qemu-system-x86_64 \
  -m 1024 \
  -net nic \
  -net user \
  -hda jammy-server-cloudimg-amd64.img \
  -drive file=seed.img,format=raw,index=1,media=disk \
  -nographic
```


## References

[How to run cloud-init locally](https://cloudinit.readthedocs.io/en/latest/howto/run_cloud_init_locally.html)

[Launching Ubuntu Cloud Images with QEMU](https://powersj.io/posts/ubuntu-qemu-cli/)

https://amoldighe.github.io/2017/08/19/cloud-image-kvm-qemu-nbd/

https://kashyapc.fedorapeople.org/Notes/_build/html/docs/QEMU-NBD-server-and-client.html
