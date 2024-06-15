## Ubuntu Cloud Images

```
curl -LO https://cloud-images.ubuntu.com/noble/current/SHA256SUMS
curl -LO https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
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
  noble-server-cloudimg-amd64.img \
  noble-server-cloudimg-amd64.raw
```

Find the offset of where the partition starts:
```
$ fdisk -l noble-server-cloudimg-amd64.raw
Disk noble-server-cloudimg-amd64.raw: 3.5 GiB, 3758096384 bytes, 7340032 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 3D4B86B5-0A3F-4A35-B0A5-8B861E8E30B1

Device                              Start     End Sectors  Size Type
noble-server-cloudimg-amd64.raw1  2099200 7339998 5240799  2.5G Linux filesystem
noble-server-cloudimg-amd64.raw14    2048   10239    8192    4M BIOS boot
noble-server-cloudimg-amd64.raw15   10240  227327  217088  106M EFI System
noble-server-cloudimg-amd64.raw16  227328 2097152 1869825  913M Linux extended b

Partition table entries are not in disk order.


# Offset is the start number times the sector size (usually 512 bytes)
$ echo $((2099200 * 512))
1074790400

# Mount the image
sudo mkdir /mnt/ubuntu-server-2404
sudo mount -o loop,offset=1074790400 noble-server-cloudimg-amd64.raw /mnt/ubuntu-server-2404

$ ls /mnt/ubuntu-server-2404/
bin                etc    lib.usr-is-merged  opt   sbin                sys
bin.usr-is-merged  home   lost+found         proc  sbin.usr-is-merged  tmp
boot               lib    media              root  snap                usr
dev                lib64  mnt                run   srv                 var
# Image contents are available as /mnt/my_image

# Unmount the iamge
sudo umount /mnt/ubuntu-server-2404
sudo rmdir /mnt/ubuntu-server-2404
```

## Mount cloud image with qemu-nbd

```
# Load the nbd module
$ sudo modprobe -v nbd
insmod /lib/modules/6.5.0-35-generic/kernel/drivers/block/nbd.ko
# Verify the nbd module is loaded
$ lsmod | grep nbd
nbd                    65536  0

$ ls /dev/nbd*
/dev/nbd0   /dev/nbd11  /dev/nbd14  /dev/nbd3  /dev/nbd6  /dev/nbd9
/dev/nbd1   /dev/nbd12  /dev/nbd15  /dev/nbd4  /dev/nbd7
/dev/nbd10  /dev/nbd13  /dev/nbd2   /dev/nbd5  /dev/nbd8

# Connect the QCOW2 image as a network block device
sudo qemu-nbd --connect=/dev/nbd0 noble-server-cloudimg-amd64.img

# Create a mount point directory
sudo mkdir /mnt/ubuntu-server-2404

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 3.5 GiB, 3758096384 bytes, 7340032 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 3D4B86B5-0A3F-4A35-B0A5-8B861E8E30B1

Device         Start     End Sectors  Size Type
/dev/nbd0p1  2099200 7339998 5240799  2.5G Linux filesystem
/dev/nbd0p14    2048   10239    8192    4M BIOS boot
/dev/nbd0p15   10240  227327  217088  106M EFI System
/dev/nbd0p16  227328 2097152 1869825  913M Linux extended boot

Partition table entries are not in disk order.

$ sudo mount /dev/nbd0p1 /mnt/ubuntu-server-2404

$ ls /mnt/ubuntu-server-2404/
bin                etc    lib.usr-is-merged  opt   sbin                sys
bin.usr-is-merged  home   lost+found         proc  sbin.usr-is-merged  tmp
boot               lib    media              root  snap                usr
dev                lib64  mnt                run   srv                 var

# Use chroot jail to execute commands inside of the mounted root filesystem
$ sudo chroot /mnt/ubuntu-server-2404/
root@crake-kvm-playpen:/# ls
bin                etc    lib.usr-is-merged  opt   sbin                sys
bin.usr-is-merged  home   lost+found         proc  sbin.usr-is-merged  tmp
boot               lib    media              root  snap                usr
dev                lib64  mnt                run   srv                 var
root@crake-kvm-playpen:/# exit

# Exit chroot and unmount the image file
$ sudo umount /mnt/ubuntu-server-2404/
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/ubuntu-server-2404
$ rmmod nbd
```

## Mount cloud image with guestfish

```
sudo apt-get update
sudo apt-get install libguestfs-tools

$ guestfish --version
guestfish 1.46.2

$ sudo guestfish

Welcome to guestfish, the guest filesystem shell for
editing virtual machine filesystems and disk images.

Type: ‘help’ for help on commands
      ‘man’ to read the manual
      ‘quit’ to quit the shell

><fs> add jammy-server-cloudimg-amd64.img
><fs> run
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ 00:00
><fs> list-filesystems
/dev/sda1: ext4
/dev/sda14: unknown
/dev/sda15: vfat
type 'help mount' for more help on mount
><fs> mount /dev/sda1 /
><fs> mountpoints
/dev/sda1: /
><fs>
```

## Ubuntu 24.04 Cloud Image

```
$ curl -LO https://cloud-images.ubuntu.com/noble/current/SHA256SUMS
$ curl -LO https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

$ sudo modprobe -v nbd
insmod /lib/modules/6.5.0-35-generic/kernel/drivers/block/nbd.ko
$ lsmod | grep nbd
nbd                    65536  0
$ sudo qemu-nbd --connect=/dev/nbd0 noble-server-cloudimg-amd64.img
$ sudo mkdir /mnt/ubuntu-server-2404

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 3.5 GiB, 3758096384 bytes, 7340032 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 3D4B86B5-0A3F-4A35-B0A5-8B861E8E30B1

Device         Start     End Sectors  Size Type
/dev/nbd0p1  2099200 7339998 5240799  2.5G Linux filesystem
/dev/nbd0p14    2048   10239    8192    4M BIOS boot
/dev/nbd0p15   10240  227327  217088  106M EFI System
/dev/nbd0p16  227328 2097152 1869825  913M Linux extended boot

Partition table entries are not in disk order.

$ sudo mount /dev/nbd0p1 /mnt/ubuntu-server-2404
$ sudo chroot /mnt/ubuntu-server-2404

# cat /etc/cloud/cloud.cfg
# The top level settings are used as module
# and base configuration.

# A set of users which may be applied and/or used by various modules
# when a 'default' entry is found it will reference the 'default_user'
# from the distro configuration specified below
users:
  - default

# If this is set, 'root' will not be able to ssh in and they
# will get a message to login instead as the default $user
disable_root: true

# This will cause the set+update hostname module to not operate (if true)
preserve_hostname: false

# If you use datasource_list array, keep array items in a single line.
# If you use multi line array, ds-identify script won't read array items.
# Example datasource config
# datasource:
#   Ec2:
#     metadata_urls: [ 'blah.com' ]
#     timeout: 5 # (defaults to 50 seconds)
#     max_wait: 10 # (defaults to 120 seconds)

# The modules that run in the 'init' stage
cloud_init_modules:
  - seed_random
  - bootcmd
  - write_files
  - growpart
  - resizefs
  - disk_setup
  - mounts
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - ca_certs
  - rsyslog
  - users_groups
  - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
  - wireguard
  - snap
  - ubuntu_autoinstall
  - ssh_import_id
  - keyboard
  - locale
  - set_passwords
  - grub_dpkg
  - apt_pipelining
  - apt_configure
  - ubuntu_pro
  - ntp
  - timezone
  - disable_ec2_metadata
  - runcmd
  - byobu

# The modules that run in the 'final' stage
cloud_final_modules:
  - package_update_upgrade_install
  - fan
  - landscape
  - lxd
  - ubuntu_drivers
  - write_files_deferred
  - puppet
  - chef
  - ansible
  - mcollective
  - salt_minion
  - reset_rmc
  - scripts_vendor
  - scripts_per_once
  - scripts_per_boot
  - scripts_per_instance
  - scripts_user
  - ssh_authkey_fingerprints
  - keys_to_console
  - install_hotplug
  - phone_home
  - final_message
  - power_state_change

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
  # This will affect which distro class gets used
  distro: ubuntu
  # Default user name + that default users groups (if added/used)
  default_user:
    name: ubuntu
    lock_passwd: True
    gecos: Ubuntu
    groups: [adm, cdrom, dip, lxd, sudo]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  network:
    dhcp_client_priority: [dhcpcd, dhclient, udhcpc]
    renderers: ['netplan', 'eni', 'sysconfig']
    activators: ['netplan', 'eni', 'network-manager', 'networkd']
  # Automatically discover the best ntp_client
  ntp_client: auto
  # Other config here will be given to the distro class and/or path classes
  paths:
    cloud_dir: /var/lib/cloud/
    templates_dir: /etc/cloud/templates/
  package_mirrors:
    - arches: [i386, amd64]
      failsafe:
        primary: http://archive.ubuntu.com/ubuntu
        security: http://security.ubuntu.com/ubuntu
      search:
        primary:
          - http://%(ec2_region)s.ec2.archive.ubuntu.com/ubuntu/
          - http://%(availability_zone)s.clouds.archive.ubuntu.com/ubuntu/
          - http://%(region)s.clouds.archive.ubuntu.com/ubuntu/
        security: []
    - arches: [arm64, armel, armhf]
      failsafe:
        primary: http://ports.ubuntu.com/ubuntu-ports
        security: http://ports.ubuntu.com/ubuntu-ports
      search:
        primary:
          - http://%(ec2_region)s.ec2.ports.ubuntu.com/ubuntu-ports/
          - http://%(availability_zone)s.clouds.ports.ubuntu.com/ubuntu-ports/
          - http://%(region)s.clouds.ports.ubuntu.com/ubuntu-ports/
        security: []
    - arches: [default]
      failsafe:
        primary: http://ports.ubuntu.com/ubuntu-ports
        security: http://ports.ubuntu.com/ubuntu-ports
  ssh_svcname: ssh

$ sudo umount /mnt/ubuntu-server-2404
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/ubuntu-server-2404
$ rmmod nbd
```

## Ubuntu 22.04 Cloud Image

```
$ curl -LO https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS
$ curl -LO https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

$ sudo modprobe -v nbd
insmod /lib/modules/6.5.0-35-generic/kernel/drivers/block/nbd.ko
$ lsmod | grep nbd
nbd                    65536  0
$ sudo qemu-nbd --connect=/dev/nbd0 jammy-server-cloudimg-amd64.img
$ sudo mkdir /mnt/ubuntu-server-2204

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 2.2 GiB, 2361393152 bytes, 4612096 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 6EEF80A3-1A86-4AB2-B08D-8FAD6C29F148

Device        Start     End Sectors  Size Type
/dev/nbd0p1  227328 4612062 4384735  2.1G Linux filesystem
/dev/nbd0p14   2048   10239    8192    4M BIOS boot
/dev/nbd0p15  10240  227327  217088  106M EFI System

Partition table entries are not in disk order.

$ sudo mount /dev/nbd0p1 /mnt/ubuntu-server-2204
$ sudo chroot /mnt/ubuntu-server-2204

# cat /etc/cloud/cloud.cfg
# The top level settings are used as module
# and base configuration.

# A set of users which may be applied and/or used by various modules
# when a 'default' entry is found it will reference the 'default_user'
# from the distro configuration specified below
users:
  - default

# If this is set, 'root' will not be able to ssh in and they
# will get a message to login instead as the default $user
disable_root: true

# This will cause the set+update hostname module to not operate (if true)
preserve_hostname: false

# If you use datasource_list array, keep array items in a single line.
# If you use multi line array, ds-identify script won't read array items.
# Example datasource config
# datasource:
#   Ec2:
#     metadata_urls: [ 'blah.com' ]
#     timeout: 5 # (defaults to 50 seconds)
#     max_wait: 10 # (defaults to 120 seconds)

# The modules that run in the 'init' stage
cloud_init_modules:
  - seed_random
  - bootcmd
  - write_files
  - growpart
  - resizefs
  - disk_setup
  - mounts
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - ca_certs
  - rsyslog
  - users_groups
  - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
  - wireguard
  - snap
  - ubuntu_autoinstall
  - ssh_import_id
  - keyboard
  - locale
  - set_passwords
  - grub_dpkg
  - apt_pipelining
  - apt_configure
  - ubuntu_pro
  - ntp
  - timezone
  - disable_ec2_metadata
  - runcmd
  - byobu

# The modules that run in the 'final' stage
cloud_final_modules:
  - package_update_upgrade_install
  - fan
  - landscape
  - lxd
  - ubuntu_drivers
  - write_files_deferred
  - puppet
  - chef
  - ansible
  - mcollective
  - salt_minion
  - reset_rmc
  - scripts_vendor
  - scripts_per_once
  - scripts_per_boot
  - scripts_per_instance
  - scripts_user
  - ssh_authkey_fingerprints
  - keys_to_console
  - install_hotplug
  - phone_home
  - final_message
  - power_state_change

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
  # This will affect which distro class gets used
  distro: ubuntu
  # Default user name + that default users groups (if added/used)
  default_user:
    name: ubuntu
    lock_passwd: True
    gecos: Ubuntu
    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  network:
    dhcp_client_priority: [dhclient, dhcpcd, udhcpc]
    renderers: ['netplan', 'eni', 'sysconfig']
    activators: ['netplan', 'eni', 'network-manager', 'networkd']
  # Automatically discover the best ntp_client
  ntp_client: auto
  # Other config here will be given to the distro class and/or path classes
  paths:
    cloud_dir: /var/lib/cloud/
    templates_dir: /etc/cloud/templates/
  package_mirrors:
    - arches: [i386, amd64]
      failsafe:
        primary: http://archive.ubuntu.com/ubuntu
        security: http://security.ubuntu.com/ubuntu
      search:
        primary:
          - http://%(ec2_region)s.ec2.archive.ubuntu.com/ubuntu/
          - http://%(availability_zone)s.clouds.archive.ubuntu.com/ubuntu/
          - http://%(region)s.clouds.archive.ubuntu.com/ubuntu/
        security: []
    - arches: [arm64, armel, armhf]
      failsafe:
        primary: http://ports.ubuntu.com/ubuntu-ports
        security: http://ports.ubuntu.com/ubuntu-ports
      search:
        primary:
          - http://%(ec2_region)s.ec2.ports.ubuntu.com/ubuntu-ports/
          - http://%(availability_zone)s.clouds.ports.ubuntu.com/ubuntu-ports/
          - http://%(region)s.clouds.ports.ubuntu.com/ubuntu-ports/
        security: []
    - arches: [default]
      failsafe:
        primary: http://ports.ubuntu.com/ubuntu-ports
        security: http://ports.ubuntu.com/ubuntu-ports
  ssh_svcname: ssh

# exit

$ sudo umount /mnt/ubuntu-server-2204
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/ubuntu-server-2204
$ rmmod nbd

```
