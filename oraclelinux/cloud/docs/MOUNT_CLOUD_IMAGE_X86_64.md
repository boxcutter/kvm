# Oracle Linux Cloud Images

https://docs.oracle.com/en-us/iaas/oracle-linux/kvm/index.htm#introduction

https://yum.oracle.com/oracle-linux-templates.html

https://blogs.oracle.com/linux/post/a-quick-start-with-the-oracle-linux-templates-for-kvm

## Loopback mount - requires converting qcow to raw

Install required tools:
```
sudo apt update
sudo apt install qemu-utils
```

```
# SHA256 Checksum: 7f1cf4e1fafda55bb4d837d0eeb9592d60e896fa56565081fc4d8519c0a3fd1a
$ curl -LO https://yum.oracle.com/templates/OracleLinux/OL9/u4/x86_64/OL9U4_x86_64-kvm-b234.qcow2
```

If the image is in QCOW2 format, convert it to raw:
```
qemu-img convert \
  -f qcow2 \
  -O raw \
  OL9U4_x86_64-kvm-b234.qcow2 \
  oracle-linux-9.raw
```

Find the offset of where the partition starts:
```
$ fdisk -l oracle-linux-9.raw 
Disk oracle-linux-9.raw: 37 GiB, 39728447488 bytes, 77594624 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xd0995951

Device              Boot   Start      End  Sectors Size Id Type
oracle-linux-9.raw1 *       2048  2099199  2097152   1G 83 Linux
oracle-linux-9.raw2      2099200 77594623 75495424  36G 8e Linux LVM


# Offset is the start number times the sector size (usually 512 bytes)
$ echo $((2048 * 512))
1048576

# Mount the image
sudo mkdir -p /mnt/oracle-linux-9
sudo mount -o loop,offset=1048576 oracle-linux-9.raw /mnt/oracle-linux-9

$ ls /mnt/oracle-linux-9/
config-5.15.0-206.153.7.el9uek.x86_64
efi
grub2
initramfs-5.15.0-206.153.7.el9uek.x86_64.img
loader
symvers-5.15.0-206.153.7.el9uek.x86_64.gz
System.map-5.15.0-206.153.7.el9uek.x86_64
vmlinuz-5.15.0-206.153.7.el9uek.x86_64

# Unmount the image
sudo umount /mnt/oracle-linux-9
sudo rmdir /mnt/oracle-linux-9



# Associate the raw image with a loop device
$ sudo losetup -fP --show oracle-linux-9.raw
/dev/loop14

# Map the partitions inside the loop device
$ sudo kpartx -av /dev/loop14
add map loop14p1 (252:0): 0 2097152 linear 7:14 2048
add map loop14p2 (252:1): 0 75495424 linear 7:14 2099200

# Scan and activate the LVM volumes
$ sudo vgscan
  WARNING: Not using device /dev/loop14p2 for PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI.
  WARNING: PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI prefers device /dev/mapper/loop14p2 because device is in dm subsystem.
  Found volume group "vg_main" using metadata type lvm2

$ sudo vgchange -ay
  WARNING: Not using device /dev/loop14p2 for PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI.
  WARNING: PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI prefers device /dev/mapper/loop14p2 because device is in dm subsystem.
  Cannot activate LVs in VG vg_main while PVs appear on duplicate devices.
  Cannot activate LVs in VG vg_main while PVs appear on duplicate devices.
  0 logical volume(s) in volume group "vg_main" now active

$ sudo lvs
  WARNING: Not using device /dev/loop14p2 for PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI.
  WARNING: PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI prefers device /dev/mapper/loop14p2 because device is in dm subsystem.
  LV      VG      Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root vg_main -wi------- <32.00g                                                    
  lv_swap vg_main -wi-------   4.00g

# Mount the logical volumes
$ sudo lvdisplay
  WARNING: Not using device /dev/loop14p2 for PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI.
  WARNING: PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI prefers device /dev/mapper/loop14p2 because device is in dm subsystem.
  --- Logical volume ---
  LV Path                /dev/vg_main/lv_root
  LV Name                lv_root
  VG Name                vg_main
  LV UUID                th0A10-GVEl-N64l-PMIK-JsCn-WfNb-eeOJ2t
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2024-05-21 16:49:49 +0000
  LV Status              NOT available
  LV Size                <32.00 GiB
  Current LE             8191
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
   
  --- Logical volume ---
  LV Path                /dev/vg_main/lv_swap
  LV Name                lv_swap
  VG Name                vg_main
  LV UUID                LJLa2f-zJ0Z-gcKJ-qEsa-NyAl-Ctlu-cdjJXd
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2024-05-21 16:49:49 +0000
  LV Status              NOT available
  LV Size                4.00 GiB
  Current LE             1024
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto

$ ls /dev/mapper
control  loop14p1  loop14p2

sudo mount /dev/mapper/vg_main-lv_root /mnt/oracle-linux-9

$ sudo mount /dev/mapper/loop14p1 /mnt/oracle-linux-9
$ sudo mount /dev/mapper/loop14p2 /mnt/oracle-linux-9

$ sudo umount /mnt/oracle-linux-9

$ sudo vgchange -an vg_main
  WARNING: Not using device /dev/loop14p2 for PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI.
  WARNING: PV Abj6jm-3Gbx-fGox-f7MJ-o4sd-8Evz-PaiZVI prefers device /dev/mapper/loop14p2 because device is in dm subsystem.
  0 logical volume(s) in volume group "vg_main" now active

$ sudo kpartx -dv /dev/loop14
del devmap : loop14p1
del devmap : loop14p2

$ sudo losetup -d /dev/loop14
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
$ sudo qemu-nbd --connect=/dev/nbd0 OL9U4_x86_64-kvm-b234.qcow2

# Create a mount point directory
sudo mkdir /mnt/oracle-linux-9

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 37 GiB, 39728447488 bytes, 77594624 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xd0995951

Device      Boot   Start      End  Sectors Size Id Type
/dev/nbd0p1 *       2048  2099199  2097152   1G 83 Linux
/dev/nbd0p2      2099200 77594623 75495424  36G 8e Linux LVM

$ sudo mount /dev/nbd0p1 /mnt/oracle-linux-9

# Refresh physical volume cache for this device
$ sudo pvscan --cache /dev/nbd0p2
  pvscan[3597] PV /dev/nbd0p2 online.

# Activate newly found volume groups
$ sudo vgscan
  Found volume group "vg_main" using metadata type lvm2

# Mount the lvm partition to /mnt
$ ls /dev/mapper
control  vg_main-lv_root  vg_main-lv_swap

$ sudo mount /dev/mapper/vg_main-lv_root /mnt/oracle-linux-9

$ ls /mnt/oracle-linux-9/
config-5.15.0-206.153.7.el9uek.x86_64
efi
grub2
initramfs-5.15.0-206.153.7.el9uek.x86_64.img
loader
symvers-5.15.0-206.153.7.el9uek.x86_64.gz
System.map-5.15.0-206.153.7.el9uek.x86_64
vmlinuz-5.15.0-206.153.7.el9uek.x86_64

$ ls /mnt/oracle-linux-9/
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var

$ sudo chroot /mnt/oracle-linux-9
basename: missing operand
Try 'basename --help' for more information.
[root@crake-kvm-playpen /]# ls
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var
[root@crake-kvm-playpen /]#
[root@crake-kvm-playpen /]# exit
exit

# Exit chroot and unmount the image file
$ sudo umount /mnt/oracle-linux-9
$ sudo vgchange -an 
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/oracle-linux-9
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

><fs> add OL9U4_x86_64-kvm-b234.qcow2
><fs> run
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ --:--
><fs> list-filesystems
/dev/sda1: xfs
/dev/vg_main/lv_root: xfs
/dev/vg_main/lv_swap: swap
><fs> mount /dev/vg_main/lv_root /
><fs> ! mkdir /mnt/oracle-linux-9
><fs> mount-local /mnt/oracle-linux-9 readonly:true
><fs> mount-local-run

== On your host terminal ==
[root@local images]# fusermount -u /tmp/mnt
== On the guestfish shell ==
><fs> mount-local-run
><fs> exit
```

## Oracle Linux 9 Cloud Image

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
  - set_passwords
  - yum_add_repo
  - timezone
  - disable_ec2_metadata
  - runcmd

# The modules that run in the 'final' stage
cloud_final_modules:
  - package_update_upgrade_install
  - puppet
  - chef
  - ansible
  - mcollective
  - salt_minion
  - rightscale_userdata
  - scripts_vendor
  - scripts_per_once
  - scripts_per_boot
  - scripts_per_instance
  - scripts_user
  - ssh_authkey_fingerprints
  - keys_to_console
  - phone_home
  - final_message
  - power_state_change

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
  # This will affect which distro class gets used
  distro: rhel
  # Default user name + that default users groups (if added/used)
  default_user:
    name: cloud-user
    lock_passwd: true
    gecos: Cloud User
    groups: [adm, systemd-journal]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  # Other config here will be given to the distro class and/or path classes
  paths:
    cloud_dir: /var/lib/cloud/
    templates_dir: /etc/cloud/templates/
  ssh_svcname: sshd
```

```
# ls /etc/cloud/cloud.cfg.d
05_logging.cfg  90_ol.cfg  README

# cat /etc/cloud/cloud.cfg.d/README 
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.

# cat /etc/cloud/cloud.cfg.d/05_logging.cfg 
## This yaml formated config file handles setting
## logger information.  The values that are necessary to be set
## are seen at the bottom.  The top '_log' are only used to remove
## redundency in a syslog and fallback-to-file case.
##
## The 'log_cfgs' entry defines a list of logger configs
## Each entry in the list is tried, and the first one that
## works is used.  If a log_cfg list entry is an array, it will
## be joined with '\n'.
_log:
 - &log_base |
   [loggers]
   keys=root,cloudinit
   
   [handlers]
   keys=consoleHandler,cloudLogHandler
   
   [formatters]
   keys=simpleFormatter,arg0Formatter
   
   [logger_root]
   level=DEBUG
   handlers=consoleHandler,cloudLogHandler
   
   [logger_cloudinit]
   level=DEBUG
   qualname=cloudinit
   handlers=
   propagate=1
   
   [handler_consoleHandler]
   class=StreamHandler
   level=WARNING
   formatter=arg0Formatter
   args=(sys.stderr,)
   
   [formatter_arg0Formatter]
   format=%(asctime)s - %(filename)s[%(levelname)s]: %(message)s
   
   [formatter_simpleFormatter]
   format=[CLOUDINIT] %(filename)s[%(levelname)s]: %(message)s
 - &log_file |
   [handler_cloudLogHandler]
   class=FileHandler
   level=DEBUG
   formatter=arg0Formatter
   args=('/var/log/cloud-init.log', 'a', 'UTF-8')
 - &log_syslog |
   [handler_cloudLogHandler]
   class=handlers.SysLogHandler
   level=DEBUG
   formatter=simpleFormatter
   args=("/dev/log", handlers.SysLogHandler.LOG_USER)

log_cfgs:
# Array entries in this list will be joined into a string
# that defines the configuration.
#
# If you want logs to go to syslog, uncomment the following line.
# - [ *log_base, *log_syslog ]
#
# The default behavior is to just log to a file.
# This mechanism that does not depend on a system service to operate.
 - [ *log_base, *log_file ]
# A file path can also be used.
# - /etc/log.conf

# This tells cloud-init to redirect its stdout and stderr to
# 'tee -a /var/log/cloud-init-output.log' so the user can see output
# there without needing to look on the console.
output: {all: '| tee -a /var/log/cloud-init-output.log'}

# cat /etc/cloud/cloud.cfg.d/90_ol.cfg 
# Provide sensible defaults for OL - see Orabug 34821447
system_info:
  default_user:
    name: cloud-user
    lock_passwd: true
    gecos: Cloud User
    groups: [adm, systemd-journal]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  distro: rhel
  paths:
    cloud_dir: /var/lib/cloud
    templates_dir: /etc/cloud/templates
  ssh_svcname: sshd
```

```
# ls /etc/cloud/templates/
chef_client.rb.tmpl                   hosts.mariner.tmpl
chrony.conf.alpine.tmpl               hosts.photon.tmpl
chrony.conf.centos.tmpl               hosts.redhat.tmpl
chrony.conf.cos.tmpl                  hosts.suse.tmpl
chrony.conf.debian.tmpl               ntp.conf.alpine.tmpl
chrony.conf.fedora.tmpl               ntp.conf.debian.tmpl
chrony.conf.freebsd.tmpl              ntp.conf.fedora.tmpl
chrony.conf.opensuse-leap.tmpl        ntp.conf.freebsd.tmpl
chrony.conf.opensuse-microos.tmpl     ntp.conf.opensuse.tmpl
chrony.conf.opensuse.tmpl             ntp.conf.photon.tmpl
chrony.conf.opensuse-tumbleweed.tmpl  ntp.conf.rhel.tmpl
chrony.conf.photon.tmpl               ntp.conf.sles.tmpl
chrony.conf.rhel.tmpl                 ntp.conf.ubuntu.tmpl
chrony.conf.sle_hpc.tmpl              ntpd.conf.openbsd.tmpl
chrony.conf.sle-micro.tmpl            resolv.conf.tmpl
chrony.conf.sles.tmpl                 sources.list.debian.deb822.tmpl
chrony.conf.ubuntu.tmpl               sources.list.debian.tmpl
hosts.alpine.tmpl                     sources.list.ubuntu.deb822.tmpl
hosts.arch.tmpl                       sources.list.ubuntu.tmpl
hosts.debian.tmpl                     systemd.resolved.conf.tmpl
hosts.freebsd.tmpl                    timesyncd.conf.tmpl
hosts.gentoo.tmpl
```
