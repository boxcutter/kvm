# Oracle Linux Cloud Images

https://yum.oracle.com/oracle-linux-templates.html

https://blogs.oracle.com/linux/post/a-quick-start-with-the-oracle-linux-templates-for-kvm

## Mount cloud image with qemu-nbd

```
$ curl -LO https://yum.oracle.com/templates/OracleLinux/OL9/u4/aarch64/OL9U4_aarch64-kvm-cloud-b90.qcow2
```

```
# Load the nbd module
$ sudo modprobe -v nbd
insmod /lib/modules/5.10.192-tegra/kernel/drivers/block/nbd.ko

# Verify the nbd module is loaded
$ lsmod | grep nbd
nbd                    45056  0

$ ls /dev/nbd*
/dev/nbd0   /dev/nbd11  /dev/nbd14  /dev/nbd3  /dev/nbd6  /dev/nbd9
/dev/nbd1   /dev/nbd12  /dev/nbd15  /dev/nbd4  /dev/nbd7
/dev/nbd10  /dev/nbd13  /dev/nbd2   /dev/nbd5  /dev/nbd8

# Connect the QCOW2 image as a network block device
sudo qemu-nbd --connect=/dev/nbd0 OL9U4_aarch64-kvm-cloud-b90.qcow2

# Create a mount point directory
sudo mkdir /mnt/oracle-linux-9

$ $ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 16 GiB, 17179869184 bytes, 33554432 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 3B884BAC-28D0-477E-A3B1-EAF10C9F4BA1

Device         Start      End  Sectors  Size Type
/dev/nbd0p1     2048  1050623  1048576  512M EFI System
/dev/nbd0p2  1050624  3147775  2097152    1G Linux filesystem
/dev/nbd0p3  3147776 11536383  8388608    4G Linux swap
/dev/nbd0p4 11536384 33552383 22016000 10.5G Linux filesystem

$ sudo mount /dev/nbd0p4 /mnt/oracle-linux-9
```
