## CentOS Cloud Images

More detailed documentation on cloud-init with RHEL can be found here:
https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_cloud-init_for_rhel_9/configuring-cloud-init_cloud-content#configuring-cloud-init_cloud-content

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

$ sudo mount /dev/nbd0p2 /mnt/centos-stream-9

$ ls /mnt/centos-stream-9
afs  boot  etc   lib    media  opt   root  sbin  sys  usr
bin  dev   home  lib64  mnt    proc  run   srv   tmp  var

# Use chroot jail to execute commands inside of the mounted root filesystem
$ sudo chroot /mnt/my_image
root@sfo2-kvm-playpen-ubuntu2204-desktop:/# ls
bin   dev  home  lib32  libx32      media  opt   root  sbin  srv  tmp  var
boot  etc  lib   lib64  lost+found  mnt    proc  run   snap  sys  usr
root@sfo2-kvm-playpen-ubuntu2204-desktop:/#

# Exit chroot and unmount the image file
$ sudo umount /mnt/centos-stream-9
$ sudo qemu-nbd --disconnect /dev/nbd0
$ sudo rmdir /mnt/cento-stream-9
```

```
$ cat cloud.cfg
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
