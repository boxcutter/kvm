## CentOS Cloud Images

## Loopback mount - requires converting qcow to raw

Install required tools:
```
sudo apt update
sudo apt install qemu-utils
```

```
curl -LO https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-x86_64-9-latest.x86_64.qcow2.SHA256SUM
curl -LO https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-x86_64-9-latest.x86_64.qcow2
```

If the image is in QCOW2 format, convert it to raw:
```
qemu-img convert \
  -f qcow2 \
  -O raw \
  CentOS-Stream-GenericCloud-x86_64-9-latest.x86_64.qcow2 \
  centos-stream-9.raw 
```

Find the offset of where the partition starts:
```
$ fdisk -l centos-stream-9.raw 
Disk centos-stream-9.raw: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: D35E8B09-A522-4054-B7A4-EFB368F44E29

Device                 Start      End  Sectors  Size Type
centos-stream-9.raw1    2048     4095     2048    1M BIOS boot
centos-stream-9.raw2    4096   413695   409600  200M EFI System
centos-stream-9.raw3  413696  2510847  2097152    1G Linux extended boot
centos-stream-9.raw4 2510848 20969471 18458624  8.8G Linux filesystem


# Offset is the start number times the sector size (usually 512 bytes)
$ echo $((2510848 * 512))
1285554176

# Mount the image
sudo mkdir /mnt/centos-stream-9
sudo mount -o loop,offset=1285554176 centos-stream-9.raw /mnt/centos-stream-9

# Image contents are available as /mnt/my_image
$ ls /mnt/centos-stream-9/
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var

# Unmount the image
sudo umount /mnt/centos-stream-9
sudo rmdir /mnt/centos-stream-9
```

## Mount cloud image with qemu-nbd

```
# Load the nbd module
sudo modprobe -v nbd
# Verify the nbd module is loaded
$ lsmod | grep nbd
nbd                    65536  0

$ ls /dev/nbd*
/dev/nbd0   /dev/nbd11  /dev/nbd14  /dev/nbd3  /dev/nbd6  /dev/nbd9
/dev/nbd1   /dev/nbd12  /dev/nbd15  /dev/nbd4  /dev/nbd7
/dev/nbd10  /dev/nbd13  /dev/nbd2   /dev/nbd5  /dev/nbd8

# Connect the QCOW2 image as a network block device
sudo qemu-nbd --connect=/dev/nbd0 CentOS-Stream-GenericCloud-x86_64-9-latest.x86_64.qcow2

# Create a mount point directory
sudo mkdir /mnt/centos-stream-9

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: D35E8B09-A522-4054-B7A4-EFB368F44E29

Device        Start      End  Sectors  Size Type
/dev/nbd0p1    2048     4095     2048    1M BIOS boot
/dev/nbd0p2    4096   413695   409600  200M EFI System
/dev/nbd0p3  413696  2510847  2097152    1G Linux extended boot
/dev/nbd0p4 2510848 20969471 18458624  8.8G Linux filesystem

$ sudo mount /dev/nbd0p4 /mnt/centos-stream-9

$ ls /mnt/centos-stream-9
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var

# Use chroot jail to execute commands inside of the mounted root filesystem
$ sudo chroot /mnt/centos-stream-9/
basename: missing operand
Try 'basename --help' for more information.
[root@crake-kvm-playpen /]# ls
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var
[root@crake-kvm-playpen /]#

# Exit chroot and unmount the image file
$ sudo umount /mnt/centos-stream-9
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/centos-stream-9
```

## Mount cloud image with guestfish

```
sudo apt-get update
sudo apt-get install libguestfs-tools

$ guestfish --version
guestfish 1.46.2

# guestfish --ro -a test1-base
$ sudo guestfish

Welcome to guestfish, the guest filesystem shell for
editing virtual machine filesystems and disk images.

Type: ‘help’ for help on commands
      ‘man’ to read the manual
      ‘quit’ to quit the shell

><fs> add CentOS-Stream-GenericCloud-x86_64-9-latest.x86_64.qcow2
><fs> run
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ 00:00
><fs> list-filesystems
/dev/sda1: unknown
/dev/sda2: vfat
/dev/sda3: xfs
/dev/sda4: xfs
><fs>
><fs> mount /dev/sda4 /
><fs> ! mkdir /mnt/centos-stream-9
><fs> mount-local /mnt/centos-stream-9 readonly:true
><fs> mount-local-run

== On your host terminal ==
[root@local images]# fusermount -u /tmp/mnt
== On the guestfish shell ==
><fs> mount-local-run
><fs> exit
```

## CentOS Stream 9 Cloud Image

```
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

mount_default_fields: [~, ~, 'auto', 'defaults,nofail,x-systemd.requires=cloud-init.service,_netdev', '0', '2']
resize_rootfs_tmp: /dev
ssh_pwauth: false

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

# Default redhat settings:
ssh_deletekeys: true
ssh_genkeytypes: ['rsa', 'ecdsa', 'ed25519']
syslog_fix_perms: ~
disable_vmware_customization: false
# The modules that run in the 'init' stage
cloud_init_modules:
  - migrator
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
  - ssh_import_id
  - locale
  - set_passwords
  - rh_subscription
  - spacewalk
  - yum_add_repo
  - ntp
  - timezone
  - disable_ec2_metadata
  - runcmd

# The modules that run in the 'final' stage
cloud_final_modules:
  - package_update_upgrade_install
  - write_files_deferred
  - puppet
  - chef
  - ansible
  - mcollective
  - salt_minion
  - reset_rmc
  - rightscale_userdata
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
  distro: centos
  # Default user name + that default users groups (if added/used)
  default_user:
    name: cloud-user
    lock_passwd: True
    gecos: Cloud User
    groups: [adm, systemd-journal]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  network:
    renderers: ['sysconfig', 'eni', 'netplan', 'network-manager', 'networkd']
  # Other config here will be given to the distro class and/or path classes
  paths:
    cloud_dir: /var/lib/cloud/
    templates_dir: /etc/cloud/templates/
  ssh_svcname: sshd
```
