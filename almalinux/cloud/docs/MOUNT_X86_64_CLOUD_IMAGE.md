# AlmaLinux OS Generic Cloud (Cloud-init) images

https://wiki.almalinux.org/cloud/Generic-cloud.html#download-images

https://github.com/AlmaLinux/cloud-images

```
curl -LO https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/CHECKSUM
curl -LO https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
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
  AlmaLinux-9-GenericCloud-latest.x86_64.qcow2 \
  almalinux-9-x86_64.raw
```

Find the offset of where the partition starts:

```
$ fdisk -l almalinux-9-x86_64.raw 
Disk almalinux-9-x86_64.raw: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: BFCF6B5D-2B26-45A9-9A0D-4793FB0D30B5

Device                    Start      End  Sectors  Size Type
almalinux-9-x86_64.raw1    2048     4095     2048    1M BIOS boot
almalinux-9-x86_64.raw2    4096   413695   409600  200M EFI System
almalinux-9-x86_64.raw3  413696  2510847  2097152    1G Linux filesystem
almalinux-9-x86_64.raw4 2510848 20969471 18458624  8.8G Linux filesystem


# Offset is the start number times the sector size (usually 512 bytes)
$ echo $((2510848 * 512))
1285554176

# Mount the image
sudo mkdir -p /mnt/almalinux-9
sudo mount -o loop,offset=1285554176 almalinux-9-x86_64.raw /mnt/almalinux-9

$ ls /mnt/almalinux-9/
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var

# Unmount the image
$ sudo umount /mnt/almalinux-9
$ sudo rmdir /mnt/almalinux-9/
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
$ sudo qemu-nbd --connect=/dev/nbd0 AlmaLinux-9-GenericCloud-latest.x86_64.qcow2

# Create a mount point directory
sudo mkdir -p /mnt/almalinux-9

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: BFCF6B5D-2B26-45A9-9A0D-4793FB0D30B5

Device        Start      End  Sectors  Size Type
/dev/nbd0p1    2048     4095     2048    1M BIOS boot
/dev/nbd0p2    4096   413695   409600  200M EFI System
/dev/nbd0p3  413696  2510847  2097152    1G Linux filesystem
/dev/nbd0p4 2510848 20969471 18458624  8.8G Linux filesystem


$ sudo mount /dev/nbd0p4 /mnt/almalinux-9

$ ls /mnt/almalinux-9/
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var

$ sudo chroot /mnt/almalinux-9/
basename: missing operand
Try 'basename --help' for more information.
[root@crake-kvm-playpen /]# ls
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var
[root@crake-kvm-playpen /]# exit
exit

# Unmount the image file
$ sudo umount /mnt/almalinux-9
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/almalinux-9
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

><fs> add AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
><fs> list-filesystems
libguestfs: error: list_filesystems: call launch before using this function
(in guestfish, don't forget to use the 'run' command)
><fs> run
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ --:--
><fs> list-filesystems
/dev/sda1: unknown
/dev/sda2: vfat
/dev/sda3: xfs
/dev/sda4: xfs
><fs> mount /dev/sda4 /
><fs> mountpoints
/dev/sda4: /
><fs> ! mkdir -p /mnt/almalinux-9 readonly:true
><fs> mount-local /mnt/almalinux-9 readonly:true
><fs> mount-local-run

# Open a different terminal
$ sudo su -
root@crake-kvm-playpen:~# ls /mnt/almalinux-9/
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var
root@crake-kvm-playpen:~# fusermount -u /mnt/almalinux-9
root@crake-kvm-playpen:~# exit
logout

== On your host terminal ==
[root@local images]# fusermount -u /tmp/mnt
== On the guestfish shell ==
><fs> mount-local-run
><fs> exit
```

## AlmaLinux 9 Cloud Image

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
  distro: almalinux
  # Default user name + that default users groups (if added/used)
  default_user:
    name: almalinux
    lock_passwd: True
    gecos: almalinux Cloud User
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

```
# ls /etc/cloud/cloud.cfg.d
05_logging.cfg  README

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
```

```
# ls /etc/cloud/templates/
chef_client.rb.tmpl                   hosts.mariner.tmpl
chrony.conf.almalinux.tmpl            hosts.photon.tmpl
chrony.conf.alpine.tmpl               hosts.redhat.tmpl
chrony.conf.centos.tmpl               hosts.suse.tmpl
chrony.conf.cloudlinux.tmpl           ntp.conf.almalinux.tmpl
chrony.conf.cos.tmpl                  ntp.conf.alpine.tmpl
chrony.conf.debian.tmpl               ntp.conf.cloudlinux.tmpl
chrony.conf.fedora.tmpl               ntp.conf.debian.tmpl
chrony.conf.freebsd.tmpl              ntp.conf.fedora.tmpl
chrony.conf.opensuse-leap.tmpl        ntp.conf.freebsd.tmpl
chrony.conf.opensuse-microos.tmpl     ntp.conf.opensuse.tmpl
chrony.conf.opensuse-tumbleweed.tmpl  ntp.conf.photon.tmpl
chrony.conf.opensuse.tmpl             ntp.conf.rhel.tmpl
chrony.conf.photon.tmpl               ntp.conf.sles.tmpl
chrony.conf.rhel.tmpl                 ntp.conf.ubuntu.tmpl
chrony.conf.sle-micro.tmpl            ntpd.conf.openbsd.tmpl
chrony.conf.sle_hpc.tmpl              resolv.conf.tmpl
chrony.conf.sles.tmpl                 sources.list.debian.deb822.tmpl
chrony.conf.ubuntu.tmpl               sources.list.debian.tmpl
hosts.alpine.tmpl                     sources.list.ubuntu.deb822.tmpl
hosts.arch.tmpl                       sources.list.ubuntu.tmpl
hosts.debian.tmpl                     systemd.resolved.conf.tmpl
hosts.freebsd.tmpl                    timesyncd.conf.tmpl
hosts.gentoo.tmpl
```
