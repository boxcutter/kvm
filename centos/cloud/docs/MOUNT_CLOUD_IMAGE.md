## CentOS Cloud Images

```
curl -LO https://cloud.centos.org/centos/9-stream/aarch64/images/CentOS-Stream-GenericCloud-9-latest.aarch64.qcow2.SHA256SUM
curl -LO https://cloud.centos.org/centos/9-stream/aarch64/images/CentOS-Stream-GenericCloud-9-latest.aarch64.qcow2
```

## Mount cloud image without any special tooling

## Mount cloud image with qemu-nbd

```
# Load the nbd module
sudo modprobe nbd
# Verify the nbd module is loaded
$ lsmod | grep nbd
nbd                    45056  0

$ ls /dev/nbd*
/dev/nbd0   /dev/nbd11  /dev/nbd14  /dev/nbd3  /dev/nbd6  /dev/nbd9
/dev/nbd1   /dev/nbd12  /dev/nbd15  /dev/nbd4  /dev/nbd7
/dev/nbd10  /dev/nbd13  /dev/nbd2   /dev/nbd5  /dev/nbd8

# Connect the QCOW2 image as a network block device
sudo qemu-nbd --connect=/dev/nbd0 CentOS-Stream-GenericCloud-9-latest.aarch64.qcow2

# Create a mount point directory
sudo mkdir /mnt/centos-stream-9

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 7CE4EB46-71F6-4CDF-996E-CD14E23CD42B

Device        Start      End  Sectors  Size Type
/dev/nbd0p1    2048  1230847  1228800  600M EFI System
/dev/nbd0p2 1230848 17614847 16384000  7.8G Linux filesystem

# Install XFS filesystem support
$ sudo apt-get update
$ sudo apt-get install xfsprogs
# Load xfs kernel module/driver
$ sudo modprobe -v xfs

$ sudo mount /dev/nbd0p1 /mnt/centos-stream-9

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
