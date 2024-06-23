# Debian Cloud Images

```
curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS
curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
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
  debian-12-generic-amd64.qcow2 \
  debian-12-generic-amd64.raw
```

Find the offset of where the partition starts:

```
$ fdisk -l debian-12-generic-amd64.raw
Disk debian-12-generic-amd64.raw: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 4BFB4C2D-4451-4D49-AD50-137B6DA8124F

Device                         Start     End Sectors  Size Type
debian-12-generic-amd64.raw1  262144 4192255 3930112  1.9G Linux root (x86
debian-12-generic-amd64.raw14   2048    8191    6144    3M BIOS boot
debian-12-generic-amd64.raw15   8192  262143  253952  124M EFI System

Partition table entries are not in disk order.


# Offset is the start number times the sector size (usually 512 bytes)
$ echo $((262144 * 512))
134217728

# Mount the image
sudo mkdir /mnt/debian-12
sudo mount -o loop,offset=134217728 debian-12-generic-amd64.raw /mnt/debian-12

$ ls /mnt/debian-12
bin   dev  home  lib64       media  opt   root  sbin  sys  usr
boot  etc  lib   lost+found  mnt    proc  run   srv   tmp  var

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
$ sudo qemu-nbd --connect=/dev/nbd0 debian-12-generic-amd64.qcow2

# Create a mount point directory
$ sudo mkdir /mnt/debian-12

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 4BFB4C2D-4451-4D49-AD50-137B6DA8124F

Device        Start     End Sectors  Size Type
/dev/nbd0p1  262144 4192255 3930112  1.9G Linux root (x86-64)
/dev/nbd0p14   2048    8191    6144    3M BIOS boot
/dev/nbd0p15   8192  262143  253952  124M EFI System

Partition table entries are not in disk order.


$ sudo mount /dev/nbd0p1 /mnt/debian-12/

$ ls /mnt/debian-12/
bin   dev  home  lib64       media  opt   root  sbin  sys  usr
boot  etc  lib   lost+found  mnt    proc  run   srv   tmp  var

# Use chroot jail to execute commands inside of the mounted root filesystem
$ sudo chroot /mnt/debian-12
root@crake-kvm-playpen:/# ls
bin   dev  home  lib64	     media  opt   root	sbin  sys  usr
boot  etc  lib	 lost+found  mnt    proc  run	srv   tmp  var
root@crake-kvm-playpen:/# exit
exit

# Exit chroot and unmount the image file
$ sudo umount /mnt/debian-12
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/debian-12
$ sudo rmmod nbd
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

><fs> add debian-12-genericcloud-amd64.qcow2
><fs> run
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ 00:00
><fs> list-filesystems
/dev/sda1: ext4
/dev/sda14: unknown
/dev/sda15: vfat
><fs> mount /dev/sda1 /
><fs> mountpoints
/dev/sda1: /
><fs> exit
```

## Debian 12/Bookworm Cloud Image

```
$ curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS
$ curl -LO https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

$ sudo modprobe -v nbd
insmod /lib/modules/6.5.0-41-generic/kernel/drivers/block/nbd.ko
$ lsmod | grep nbd
nbd                    65536  0
$ sudo qemu-nbd --connect=/dev/nbd0 debian-12-generic-amd64.qcow2
$ sudo mkdir /mnt/debian-12

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 2 GiB, 2147483648 bytes, 4194304 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 4BFB4C2D-4451-4D49-AD50-137B6DA8124F

Device        Start     End Sectors  Size Type
/dev/nbd0p1  262144 4192255 3930112  1.9G Linux root (x86-64)
/dev/nbd0p14   2048    8191    6144    3M BIOS boot
/dev/nbd0p15   8192  262143  253952  124M EFI System

Partition table entries are not in disk order.

$ sudo mount /dev/nbd0p1 /mnt/debian-12/
$ sudo chroot /mnt/debian-12/
root@crake-kvm-playpen:~# exit
exit
$ sudo umount /mnt/debian-12
$ sudo rmdir /mnt/debian-12
```

```
# cat /etc/cloud/cloud.cfg
# The top level settings are used as module
# and system configuration.
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

apt:
   # This prevents cloud-init from rewriting apt's sources.list file,
   # which has been a source of surprise.
   preserve_sources_list: true

# If you use datasource_list array, keep array items in a single line.
# If you use multi line array, ds-identify script won't read array items.
# Example datasource config
# datasource:
#    Ec2:
#      metadata_urls: [ 'blah.com' ]
#      timeout: 5 # (defaults to 50 seconds)
#      max_wait: 10 # (defaults to 120 seconds)




# The modules that run in the 'init' stage
cloud_init_modules:
 - migrator
 - seed_random
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - disk_setup
 - mounts
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ca-certs
 - rsyslog
 - users-groups
 - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
 - snap
 - ssh-import-id
 - keyboard
 - locale
 - set-passwords
 - grub-dpkg
 - apt-pipelining
 - apt-configure
 - ntp
 - timezone
 - disable-ec2-metadata
 - runcmd
 - byobu

# The modules that run in the 'final' stage
cloud_final_modules:
 - package-update-upgrade-install
 - fan
 - landscape
 - lxd
 - write-files-deferred
 - puppet
 - chef
 - mcollective
 - salt-minion
 - reset_rmc
 - refresh_rmc_and_interface
 - rightscale_userdata
 - scripts-vendor
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - install-hotplug
 - phone-home
 - final-message
 - power-state-change

# System and/or distro specific settings
# (not accessible to handlers/transforms)
system_info:
   # This will affect which distro class gets used
   distro: debian
   # Default user name + that default users groups (if added/used)
   default_user:
     name: debian
     lock_passwd: True
     gecos: Debian
     groups: [adm, audio, cdrom, dialout, dip, floppy, netdev, plugdev, sudo, video]
     sudo: ["ALL=(ALL) NOPASSWD:ALL"]
     shell: /bin/bash
   # Other config here will be given to the distro class and/or path classes
   paths:
      cloud_dir: /var/lib/cloud/
      templates_dir: /etc/cloud/templates/
   package_mirrors:
     - arches: [default]
       failsafe:
         primary: https://deb.debian.org/debian
         security: https://deb.debian.org/debian-security
   ssh_svcname: ssh
```

```
# cat /etc/cloud/clean.d/README
-- cloud-init's clean.d run-parts directory --

This directory is provided for third party applications which need
additional configuration artifact cleanup from the filesystem when
the command `cloud-init clean` is invoked.

The `cloud-init clean` operation is typically performed by image creators
when preparing a golden image for clone and redeployment. The clean command
removes any cloud-init semaphores, allowing cloud-init to treat the next
boot of this image as the "first boot". When the image is next booted
cloud-init will performing all initial configuration based on any valid
datasource meta-data and user-data.

Any executable scripts in this subdirectory will be invoked in lexicographical
order with run-parts by the command: sudo cloud-init clean.

Typical format of such scripts would be a ##-<some-app> like the following:
  /etc/cloud/clean.d/99-live-installer
```

```
# cat /etc/cloud/cloud.cfg.d/README
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.

# cat /etc/cloud/cloud.cfg.d/01_debian_cloud.cfg 
apt:
  generate_mirrorlists: true

system_info:
  default_user:
    name: debian
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: True
    gecos: Debian
    groups: [adm, audio, cdrom, dialout, dip, floppy, plugdev, sudo, video]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash

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
chef_client.rb.tmpl	   hosts.photon.tmpl
chrony.conf.alpine.tmpl    hosts.redhat.tmpl
chrony.conf.centos.tmpl    hosts.suse.tmpl
chrony.conf.cos.tmpl	   ntp.conf.alpine.tmpl
chrony.conf.debian.tmpl    ntp.conf.debian.tmpl
chrony.conf.fedora.tmpl    ntp.conf.fedora.tmpl
chrony.conf.freebsd.tmpl   ntp.conf.freebsd.tmpl
chrony.conf.opensuse.tmpl  ntp.conf.opensuse.tmpl
chrony.conf.photon.tmpl    ntp.conf.photon.tmpl
chrony.conf.rhel.tmpl	   ntp.conf.rhel.tmpl
chrony.conf.sles.tmpl	   ntp.conf.sles.tmpl
chrony.conf.ubuntu.tmpl    ntp.conf.ubuntu.tmpl
host.mariner.tmpl	   ntpd.conf.openbsd.tmpl
hosts.alpine.tmpl	   resolv.conf.tmpl
hosts.arch.tmpl		   sources.list.debian.tmpl
hosts.debian.tmpl	   sources.list.ubuntu.tmpl
hosts.freebsd.tmpl	   systemd.resolved.conf.tmpl
hosts.gentoo.tmpl	   timesyncd.conf.tmpl
```

