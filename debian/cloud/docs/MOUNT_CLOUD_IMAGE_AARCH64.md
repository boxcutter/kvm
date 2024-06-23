# Debian Cloud Images

```
curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS
curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-arm64.qcow2
```

## Loopback mount - requires converting qcow to raw

Install required tools:

```
sudo apt update
sudo apt install qemu-utils
```

If the image is in QCOW2 format, convert it to raw:

```
qemu-img convert \
  -f qcow2 \
  -O raw \
  debian-12-genericcloud-arm64.qcow2 \
  debian-12-genericcloud-arm64.raw
```

Find the offset of where the partition starts:

```
$ fdisk -l debian-12-genericcloud-arm64.raw 
Disk debian-12-genericcloud-arm64.raw: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: AA17B800-9DDD-174C-87FE-0BBA5A1FF598

Device                              Start     End Sectors  Size Type
debian-12-genericcloud-arm64.raw1  262144 4192255 3930112  1.9G Linux root
debian-12-genericcloud-arm64.raw15   2048  262143  260096  127M EFI System

Partition table entries are not in disk order.


# Offset is the start number times the sector size (usually 512 bytes)
$ echo $((262144 * 512))
134217728

# Mount the image
sudo mkdir /mnt/debian-12
sudo mount -o loop,offset=134217728 debian-12-genericcloud-arm64.raw /mnt/debian-12

$ ls /mnt/debian-12/
bin   dev  home  lost+found  mnt  proc  run   srv  tmp  var
boot  etc  lib   media       opt  root  sbin  sys  usr

# Unmount the image
sudo umount /mnt/debian-12
sudo rmdir /mnt/debian-12
```

## Mount cloud image with qemu-nbd

```
# Load the nbd module
$ sudo modprobe -v nbd
insmod /lib/modules/6.5.0-41-generic/kernel/drivers/block/nbd.ko
# Verify the nbd module is loaded
$ lsmod | grep nbd
nbd                    65536  0

$ ls /dev/nbd*
/dev/nbd0   /dev/nbd11  /dev/nbd14  /dev/nbd3  /dev/nbd6  /dev/nbd9
/dev/nbd1   /dev/nbd12  /dev/nbd15  /dev/nbd4  /dev/nbd7
/dev/nbd10  /dev/nbd13  /dev/nbd2   /dev/nbd5  /dev/nbd8

# Connect the QCOW2 image as a network block device
$ sudo qemu-nbd --connect=/dev/nbd0 debian-12-genericcloud-arm64.qcow2

# Create a mount point directory
$ sudo mkdir /mnt/debian-12

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: AA17B800-9DDD-174C-87FE-0BBA5A1FF598

Device        Start     End Sectors  Size Type
/dev/nbd0p1  262144 4192255 3930112  1.9G Linux root (ARM-64)
/dev/nbd0p15   2048  262143  260096  127M EFI System

Partition table entries are not in disk order.



```
