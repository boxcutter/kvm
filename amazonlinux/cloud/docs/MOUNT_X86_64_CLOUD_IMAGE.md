# Mount Amazon Linux images

https://docs.aws.amazon.com/linux/al2023/ug/kvm-supported-configurations.html

https://docs.aws.amazon.com/linux/al2023/ug/outside-ec2-download.html

https://cdn.amazonlinux.com/os-images/latest/kvm/

```
curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.5.20240624.0/kvm/SHA256SUMS
curl -LO https://cdn.amazonlinux.com/al2023/os-images/2023.5.20240624.0/kvm/al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2
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
  al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2 \
  amazon-linux-2-x86_64.raw
```

Look at the partition layout:

```
$ fdisk -l amazon-linux-2-x86_64.raw 
Disk amazon-linux-2-x86_64.raw: 25 GiB, 26843545600 bytes, 52428800 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 89AE1D76-0E85-46C1-B3C9-A82673F17603

Device                       Start      End  Sectors Size Type
amazon-linux-2-x86_64.raw1   24576 52428766 52404191  25G Linux filesystem
amazon-linux-2-x86_64.raw127 22528    24575     2048   1M BIOS boot
amazon-linux-2-x86_64.raw128  2048    22527    20480  10M EFI System

Partition table entries are not in disk order.


# Offset is the start number times the sector size (usually 512 bytes)
$ echo $((24576 * 512))
12582912


# Mount the image
sudo mkdir -p /mnt/amazon-linux-2
sudo mount -o loop,offset=12582912 amazon-linux-2-x86_64.raw /mnt/amazon-linux-2

$ ls /mnt/amazon-linux-2/
bin   dev  home  lib64  media  opt   root  sbin  sys  usr
boot  etc  lib   local  mnt    proc  run   srv   tmp  var

# Umount the image
$ sudo umount /mnt/amazon-linux-2
$ sudo rmdir /mnt/amazon-linux-2/
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
$ sudo qemu-nbd --connect=/dev/nbd0 al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2

# Create a mount point directory
sudo mkdir -p /mnt/amazon-linux-2

$ sudo fdisk -l /dev/nbd0
Disk /dev/nbd0: 25 GiB, 26843545600 bytes, 52428800 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 89AE1D76-0E85-46C1-B3C9-A82673F17603

Device        Start      End  Sectors Size Type
/dev/nbd0p1   24576 52428766 52404191  25G Linux filesystem
/dev/nbd0p127 22528    24575     2048   1M BIOS boot
/dev/nbd0p128  2048    22527    20480  10M EFI System

Partition table entries are not in disk order.


$ sudo mount /dev/nbd0p1 /mnt/amazon-linux-2

$ ls /mnt/amazon-linux-2/
bin   dev  home  lib64  media  opt   root  sbin  sys  usr
boot  etc  lib   local  mnt    proc  run   srv   tmp  var

$ sudo chroot /mnt/amazon-linux-2/
cat: /proc/119268/comm: No such file or directory
[root@crake-kvm-playpen /]# ls
bin   dev  home  lib64  media  opt   root  sbin  sys  usr
boot  etc  lib   local  mnt    proc  run   srv   tmp  var
[root@crake-kvm-playpen /]#

[root@crake-kvm-playpen /]# exit
exit

# Unmount the image file
$ sudo umount /mnt/amazon-linux-2
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/amazon-linux-2
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

><fs> add al2023-kvm-2023.5.20240624.0-kernel-6.1-x86_64.xfs.gpt.qcow2
><fs> run
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ 00:00
><fs> list-filessytems
list-filessytems: unknown command
><fs> list-filesystems
/dev/sda1: xfs
/dev/sda127: unknown
/dev/sda128: vfat
><fs> mount /dev/sda1 /
><fs> mountpoints
/dev/sda1: /
><fs> ! mkdir -p /mnt/amazon-linux-2 readonly:true
><fs> mount-local /mnt/amazon-linux-2 readonly:true
><fs> mount-local-run

# Open a different terminal
$ sudo su -
root@crake-kvm-playpen:~# ls /mnt/amazon-linux-2
bin   dev  home  lib64  media  opt   root  sbin  sys  usr
boot  etc  lib   local  mnt    proc  run   srv   tmp  var
root@crake-kvm-playpen:~# fusermount -u /mnt/amazon-linux-2
root@crake-kvm-playpen:~# exit
logout

== On your host terminal ==
[root@local images]# fusermount -u /tmp/mnt
== On the guestfish shell ==
><fs> mount-local-run
><fs> exit
```

## Amazon Linux 2

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

mount_default_fields: [~, ~, 'auto', 'defaults,nofail', '0', '2']
resize_rootfs: noblock
resize_rootfs_tmp: /dev
ssh_pwauth:   false

# This will cause the set+update hostname module to not operate (if true)
preserve_hostname: false

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
 - write-metadata
 - growpart
 - resizefs
 - disk_setup
 - mounts
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ca-certs
 - rsyslog
 - selinux
 - users-groups
 - ssh

# The modules that run in the 'config' stage
cloud_config_modules:
 - ssh-import-id
 - keyboard
 - locale
 - set-passwords
 - yum-variables
 - yum-add-repo
 - ntp
 - timezone
 - disable-ec2-metadata
 - runcmd

# The modules that run in the 'final' stage
cloud_final_modules:
 - package-update-upgrade-install
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
   distro: amazon
   # Default user name + that default users groups (if added/used)
   default_user:
     name: ec2-user
     lock_passwd: True
     gecos: EC2 Default User
     groups: [wheel, adm, systemd-journal]
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
02_amazon-onprem.cfg  10_aws_dnfvars.cfg     README
05_logging.cfg        40_selinux-reboot.cfg

# cat /etc/cloud/cloud.cfg.d/README 
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.

# cat /etc/cloud/cloud.cfg.d/README 
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.
[root@crake-kvm-playpen /]# cat /etc/cloud/cloud.cfg.d/02_amazon-onprem.cfg 
datasource_list: [ NoCloud, AltCloud, ConfigDrive, OVF, VMware, None ]
disable_vmware_customization: false


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


# cat /etc/cloud/cloud.cfg.d/10_aws_dnfvars.cfg 
# ### DO NOT MODIFY THIS FILE! ###
# This file will be replaced if cloud-init is upgraded.
# Please put your modifications in other files under /etc/cloud/cloud.cfg.d/
#
# Note that cloud-init uses flexible merge strategies for config options
# https://cloudinit.readthedocs.org/en/latest/topics/merging.html

write_metadata:
  # Fill in yum vars for the region and domain
  - path: /etc/dnf/vars/awsregion
    data:
      - identity: region
      - "default"
  - path: /etc/dnf/vars/awsdomain
    data:
      - metadata: services/domain
      - "amazonaws.com"

# vim:syntax=yaml expandtab


# cat /etc/cloud/cloud.cfg.d/40_selinux-reboot.cfg 
power_state:
    delay: now
    mode: reboot
    message: Rebooting machine to apply SELinux kernel commandline setting
    condition: test -f /run/cloud-init-selinux-reboot
```

```
# ls /etc/cloud/templates/
chef_client.rb.tmpl        hosts.arch.tmpl         ntp.conf.photon.tmpl
chrony.conf.alpine.tmpl    hosts.debian.tmpl       ntp.conf.rhel.tmpl
chrony.conf.amazon.tmpl    hosts.freebsd.tmpl      ntp.conf.sles.tmpl
chrony.conf.debian.tmpl    hosts.gentoo.tmpl       ntp.conf.ubuntu.tmpl
chrony.conf.fedora.tmpl    hosts.photon.tmpl       resolv.conf.tmpl
chrony.conf.opensuse.tmpl  hosts.redhat.tmpl       sources.list.debian.tmpl
chrony.conf.photon.tmpl    hosts.suse.tmpl         sources.list.ubuntu.tmpl
chrony.conf.rhel.tmpl      ntp.conf.alpine.tmpl    systemd.resolved.conf.tmpl
chrony.conf.sles.tmpl      ntp.conf.debian.tmpl    timesyncd.conf.tmpl
chrony.conf.ubuntu.tmpl    ntp.conf.fedora.tmpl
hosts.alpine.tmpl          ntp.conf.opensuse.tmpl
```
