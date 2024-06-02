# Libvirt cloud images

## Create a storage pool for cloud-init boot images

> **Note:**
> There is a `--cloud-init` parameter for `virt-install` to auto-generate the
> cloud-init ISO. It creates a pool called `boot-scratch` in
> `/var/lib/libvirt/boot`. However oftentimes it's just easier to control the
> lifecycle of these images manually

```
# Create the storage pool definition
$ virsh pool-define-as \
    --name boot-scratch \
    --type dir \
    --target /var/lib/libvirt/boot
Pool iso defined

# Create the local directory
$ virsh pool-build boot-scratch
# Start the storage pool
$ virsh pool-start boot-scratch
# Turn on autostart
$ virsh pool-autostart boot-scratch

# Verify the storage pool is listed
$ virsh pool-list --all
 Name           State    Autostart
------------------------------------
 boot-scratch   active   yes
 default        active   yes
 iso            active   yes

$ virsh vol-list --pool boot-scratch --details
 Name   Path   Type   Capacity   Allocation
---------------------------------------------

# Verify the storage pool configuration
$ virsh pool-info boot-scratch
Name:           boot-scratch
UUID:           a683c9a8-83c3-442c-83fc-1e15aaba902e
State:          running
Persistent:     yes
Autostart:      yes
Capacity:       1.15 TiB
Allocation:     33.26 GiB
Available:      1.12 TiB
```

```
curl -LO https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

$ qemu-img info jammy-server-cloudimg-amd64.img 
image: jammy-server-cloudimg-amd64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 620 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16

sudo qemu-img convert -f qcow2 -O qcow2 jammy-server-cloudimg-amd64.img /var/lib/libvirt/images/ubuntu-server-2204.qcow2
sudo qemu-img resize -f qcow2 /var/lib/libvirt/images/ubuntu-server-2204.qcow2 32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: ubuntu-server-2204
local-hostname: ubuntu-server-2204
EOF

cat >user-data <<EOF
#cloud-config
password: password
chpasswd:
  expire: False
ssh_pwauth: True
EOF
```

```
sudo apt-get update
sudo apt-get install genisoimage
#     -input-charset utf-8 \
genisoimage \
    -input-charset utf-8 \
    -output ubuntu-server-2204-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp ubuntu-server-2204-cloud-init.img /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2204 \
  --boot uefi \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2204.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virt-viewer ubuntu-server-2204

# login with ubuntu user
$ cloud-init status
status: data

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ sudo shutdown -h now



$ virsh domblklist ubuntu-server-2204
 Target   Source
-------------------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-server-2204.qcow2
 sda      /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso

$ virsh change-media ubuntu-server-2204 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso
$ virsh edit ubuntu-server-2204
# remove entry for the cloud-init.iso
<!--
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='/var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
-->
```

```
virt-install \
  --name ubuntu-server-2204 \
  --memory 1024 \
  --noreboot \
  --os-variant detect=on,name=ubuntujammy \
  --disk=size=10,backing_store="$(pwd)/jammy-server-cloudimg-amd64.img" \
  --cloud-init user-data="$(pwd)/user-data,meta-data=$(pwd)/meta-data,network-config=$(pwd)/network-config"
```

12345678901234567890123456789012345678901234567890123456789012345678901234567890

## Ubuntu Server 22.04 cloud image cloud-init

```
$ ls -l /etc/cloud
total 20
-rw-r--r-- 1 root root   36 Jun  1 02:11 build.info
drwxr-xr-x 2 root root 4096 Mar 27 13:36 clean.d
-rw-r--r-- 1 root root 3766 Mar 27 13:36 cloud.cfg
drwxr-xr-x 2 root root 4096 Jun  1 02:10 cloud.cfg.d
drwxr-xr-x 2 root root 4096 Jun  1 02:10 templates
```

```
$ cat /etc/cloud/build.info 
build_name: server
serial: 20240601
```

```
$ ls -l /etc/cloud/clean.d
total 0
```

```
$ ls -l /etc/cloud/cloud.cfg.d
total 12
-rw-r--r-- 1 root root 2071 Mar 27 13:14 05_logging.cfg
-rw-r--r-- 1 root root  333 Jun  1 02:10 90_dpkg.cfg
-rw-r--r-- 1 root root  167 Mar 27 13:14 README
```

```
$ cat /etc/cloud/cloud.cfg.d/05_logging.cfg 
## This yaml formatted config file handles setting
## logger information.  The values that are necessary to be set
## are seen at the bottom.  The top '_log' are only used to remove
## redundancy in a syslog and fallback-to-file case.
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
$ cat /etc/cloud/cloud.cfg.d/90_dpkg.cfg 
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, ConfigDrive, OpenNebula, DigitalOcean, Azure, AltCloud, OVF, MAAS, GCE, OpenStack, CloudSigma, SmartOS, Bigstep, Scaleway, AliYun, Ec2, CloudStack, Hetzner, IBMCloud, Oracle, Exoscale, RbxCloud, UpCloud, VMware, Vultr, LXD, NWCS, Akamai, WSL, None ]
```

```
$ cat /etc/cloud/cloud.cfg.d/README 
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.
```

```
$ sudo netplan get
network:
  version: 2
  ethernets:
    enp1s0:
      match:
        macaddress: "52:54:00:a7:a3:60"
      dhcp4: true
      dhcp6: true
      set-name: "enp1s0"
```

```
$ sudo cat /etc/netplan/50-cloud-init.yaml 
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        enp1s0:
            dhcp4: true
            dhcp6: true
            match:
                macaddress: 52:54:00:a7:a3:60
            set-name: enp1s0
    version: 2
```


> **Note:**
> All of the subiquity-based installers make use of cloud-init

## Ubuntu Server 24.04 ISO cloud-init

```
$ ls -l /etc/cloud
total 24
drwxr-xr-x 2 root root 4096 Jun  1 17:18 clean.d
-rw-r--r-- 1 root root 3718 Apr  5 23:18 cloud.cfg
drwxr-xr-x 2 root root 4096 Jun  1 17:18 cloud.cfg.d
-rw-r--r-- 1 root root  132 Jun  1 17:20 cloud-init.disabled
-rw-r--r-- 1 root root   16 Jun  1 17:18 ds-identify.cfg
drwxr-xr-x 2 root root 4096 Apr 23 09:40 templates
```

```
$ cat /etc/cloud/cloud-init.disabled 
Disabled by Ubuntu live installer after first boot.
To re-enable cloud-init on this image run:
  sudo cloud-init clean --machine-id
```

```
$ cat /etc/cloud/ds-identify.cfg 
policy: enabled
```

```
$ ls -l /etc/cloud/clean.d
total 4
-rwxr-xr-x 1 root root 484 Jun  1 17:18 99-installer
```

```
$ cat /etc/cloud/clean.d/99-installer 
#!/usr/bin/env python3
# Remove live-installer config artifacts when running: sudo cloud-init clean
# Autogenerated by Subiquity: 2024-06-01 17:18:27.949965 UTC


import os

for cfg_file in ["/etc/cloud/cloud-init.disabled", "/etc/cloud/cloud.cfg.d/20-disable-cc-dpkg-grub.cfg", "/etc/cloud/cloud.cfg.d/90-installer-network.cfg", "/etc/cloud/cloud.cfg.d/99-installer.cfg", "/etc/cloud/ds-identify.cfg"]:
    try:
        os.remove(cfg_file)
    except FileNotFoundError:
        pass
```

```
$ ls -l /etc/cloud/cloud.cfg.d
total 28
-rw-r--r-- 1 root root 2071 Mar 27 13:14 05_logging.cfg
-rw-r--r-- 1 root root   28 Jun  1 17:18 20-disable-cc-dpkg-grub.cfg
-rw-r--r-- 1 root root  333 Apr 23 09:40 90_dpkg.cfg
-rw------- 1 root root  117 Jun  1 17:16 90-installer-network.cfg
-rw------- 1 root root  793 Jun  1 17:18 99-installer.cfg
-rw-r--r-- 1 root root   35 Jun  1 17:15 curtin-preserve-sources.cfg
-rw-r--r-- 1 root root  167 Mar 27 13:14 README
```

```
$ cat /etc/cloud/cloud.cfg.d/05_logging.cfg
## This yaml formatted config file handles setting
## logger information.  The values that are necessary to be set
## are seen at the bottom.  The top '_log' are only used to remove
## redundancy in a syslog and fallback-to-file case.
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
$ cat /etc/cloud/cloud.cfg.d/20-disable-cc-dpkg-grub.cfg 
grub_dpkg:
  enabled: false
```

```
$ cat /etc/cloud/cloud.cfg.d/90_dpkg.cfg 
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, ConfigDrive, OpenNebula, DigitalOcean, Azure, AltCloud, OVF, MAAS, GCE, OpenStack, CloudSigma, SmartOS, Bigstep, Scaleway, AliYun, Ec2, CloudStack, Hetzner, IBMCloud, Oracle, Exoscale, RbxCloud, UpCloud, VMware, Vultr, LXD, NWCS, Akamai, WSL, None ]
```

```
$ sudo cat /etc/cloud/cloud.cfg.d/90-installer-network.cfg 
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp1s0:
      dhcp4: true
  version: 2
```

```
$ sudo cat /etc/cloud/cloud.cfg.d/99-installer.cfg 
datasource:
  None:
    metadata:
      instance-id: 7fcad967-8b86-40aa-8761-58d0ed4245d5
    userdata_raw: "#cloud-config\ngrowpart:\n  mode: 'off'\nlocale: en_US.UTF-8\n\
      preserve_hostname: true\nresize_rootfs: false\nssh_pwauth: true\nusers:\n- gecos:\
      \ automat\n  groups: adm,cdrom,dip,lxd,plugdev,sudo\n  lock_passwd: false\n\
      \  name: automat\n  passwd: $6$VHMEtYQBCS/gpEYp$XghG2ozLRgkm.jGqmEMl2Q/161CjT5DbYbSRSGsYoDDLXAtUV.yRrMJdmClMi2.EAelEN1JPZ78sIIGmBXNK60\n\
      \  shell: /bin/bash\nwrite_files:\n- content: \"Disabled by Ubuntu live installer\
      \ after first boot.\\nTo re-enable cloud-init\\\n    \\ on this image run:\\\
      n  sudo cloud-init clean --machine-id\\n\"\n  defer: true\n  path: /etc/cloud/cloud-init.disabled\n"
datasource_list:
- None
```

```
$ cat /etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg 
apt:
  preserve_sources_list: true
```

```
$ cat /etc/cloud/cloud.cfg.d/README 
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.
```

## Ubuntu Server 22.04 ISO cloud-init

```
$ ls -l /etc/cloud
total 20
drwxr-xr-x 2 root root 4096 Jun  1 17:47 clean.d
-rw-r--r-- 1 root root 3756 Oct 24  2023 cloud.cfg
drwxr-xr-x 2 root root 4096 Jun  1 17:47 cloud.cfg.d
-rw-r--r-- 1 root root   16 Jun  1 17:47 ds-identify.cfg
drwxr-xr-x 2 root root 4096 Feb 16 18:48 templates
```

```
$ cat /etc/cloud/ds-identify.cfg 
policy: enabled
```

```
$ ls -l /etc/cloud/clean.d
total 8
-rwxr-xr-x 1 root root 455 Jun  1 17:47 99-installer
-rw-r--r-- 1 root root 883 Oct 24  2023 README
```

```
$ cat /etc/cloud/clean.d/99-installer 
#!/usr/bin/env python3
# Remove live-installer config artifacts when running: sudo cloud-init clean
# Autogenerated by Subiquity: 2024-06-01 17:47:12.223074 UTC


import os

for cfg_file in ["/etc/cloud/cloud.cfg.d/99-installer.cfg", "/etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg", "/etc/cloud/ds-identify.cfg", "/etc/netplan/00-installer-config.yaml"]:
    try:
        os.remove(cfg_file)
    except FileNotFoundError:
        pass
```

```
$ cat /etc/cloud/clean.d/README 
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
$ ls -l /etc/cloud/cloud.cfg.d/
total 24
-rw-r--r-- 1 root root 2070 Oct 24  2023 05_logging.cfg
-rw-r--r-- 1 root root  328 Feb 16 18:46 90_dpkg.cfg
-rw------- 1 root root  542 Jun  1 17:47 99-installer.cfg
-rw-r--r-- 1 root root   35 Jun  1 17:43 curtin-preserve-sources.cfg
-rw-r--r-- 1 root root  167 Oct 24  2023 README
-rw------- 1 root root   28 Jun  1 17:45 subiquity-disable-cloudinit-networking.cfg
```

```
$ cat /etc/cloud/cloud.cfg.d/05_logging.cfg 
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
$ cat /etc/cloud/cloud.cfg.d/90_dpkg.cfg 
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, ConfigDrive, OpenNebula, DigitalOcean, Azure, AltCloud, OVF, MAAS, GCE, OpenStack, CloudSigma, SmartOS, Bigstep, Scaleway, AliYun, Ec2, CloudStack, Hetzner, IBMCloud, Oracle, Exoscale, RbxCloud, UpCloud, VMware, Vultr, LXD, NWCS, Akamai, None ]
```

```
$ sudo cat /etc/cloud/cloud.cfg.d/99-installer.cfg 
[sudo] password for automat: 
datasource:
  None:
    metadata:
      instance-id: 1aa5ee9f-653a-4290-a6fa-83836a30ce72
    userdata_raw: "#cloud-config\ngrowpart:\n  mode: 'off'\nlocale: en_US.UTF-8\n\
      preserve_hostname: true\nresize_rootfs: false\nssh_pwauth: true\nusers:\n- gecos:\
      \ automat\n  groups: adm,cdrom,dip,lxd,plugdev,sudo\n  lock_passwd: false\n\
      \  name: automat\n  passwd: $6$tDf4cjp9f6HsAtsq$yeAA0vHqtLPAttWpz7hbQN6mCGiyyVVhgD/AW.ehH0Jyr.xrt7gItfZS7NEE9QGsdPtmctQ4lZ3kCpapJN.Gm1\n\
      \  shell: /bin/bash\n"
datasource_list:
- None
```

```
$ cat /etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg 
apt:
  preserve_sources_list: true
```

```
$ cat /etc/cloud/cloud.cfg.d/README 
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.
```

```
$ sudo cat /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg 
network: {config: disabled}
```

## Ubuntu Server 20.04 ISO cloud-init

```
$ ls -l /etc/cloud
total 20
drwxr-xr-x 2 root root 4096 Jun  1 18:19 clean.d
-rw-r--r-- 1 root root 3787 May 19  2023 cloud.cfg
drwxr-xr-x 2 root root 4096 Jun  1 18:19 cloud.cfg.d
-rw-r--r-- 1 root adm    16 Jun  1 18:08 ds-identify.cfg
drwxr-xr-x 2 root root 4096 Jun  1 18:19 templates
```

```
$ cat /etc/cloud/ds-identify.cfg 
policy: enabled
```

```
$ ls -l /etc/cloud/clean.d/
total 4
-rw-r--r-- 1 root root 883 Nov 23  2022 README
```

```
$ ls -l /etc/cloud/clean.d/
total 4
-rw-r--r-- 1 root root 883 Nov 23  2022 README
automat@ubuntu-server-2004:~$ cat /etc/cloud/clean.d/README 
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
$ ls -l /etc/cloud/cloud.cfg.d/
total 24
-rw-r--r-- 1 root root 2070 Nov 23  2022 05_logging.cfg
-rw-r--r-- 1 root root  320 Jun  1 18:19 90_dpkg.cfg
-rw------- 1 root adm   542 Jun  1 18:08 99-installer.cfg
-rw-r--r-- 1 root root   35 Jun  1 18:05 curtin-preserve-sources.cfg
-rw-r--r-- 1 root root  167 Nov 23  2022 README
-rw-r--r-- 1 root root   28 Jun  1 18:06 subiquity-disable-cloudinit-networking.cfg
```

```
$ cat /etc/cloud/cloud.cfg.d/05_logging.cfg 
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
$ cat /etc/cloud/cloud.cfg.d/90_dpkg.cfg 
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, ConfigDrive, OpenNebula, DigitalOcean, Azure, AltCloud, OVF, MAAS, GCE, OpenStack, CloudSigma, SmartOS, Bigstep, Scaleway, AliYun, Ec2, CloudStack, Hetzner, IBMCloud, Oracle, Exoscale, RbxCloud, UpCloud, VMware, Vultr, LXD, NWCS, None ]
```

```
$ sudo cat /etc/cloud/cloud.cfg.d/99-installer.cfg 
[sudo] password for automat: 
datasource:
  None:
    metadata:
      instance-id: 77521a3c-2b8a-4149-9706-e727a3d81645
    userdata_raw: "#cloud-config\ngrowpart:\n  mode: 'off'\nlocale: en_US.UTF-8\n\
      preserve_hostname: true\nresize_rootfs: false\nssh_pwauth: true\nusers:\n- gecos:\
      \ automat\n  groups: adm,cdrom,dip,lxd,plugdev,sudo\n  lock_passwd: false\n\
      \  name: automat\n  passwd: $6$xQgNaFgU.unsZFSI$cuC0eUuTshAawkNjM8dM.h.GQGLPHQ4uj/4i/z.brPKs41Dbzo77B0m.tkWHOtcvgr.IpU9T29z.wl9H456QP.\n\
      \  shell: /bin/bash\n"
datasource_list:
- None
```

```
$ cat /etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg 
apt:
  preserve_sources_list: true
```

```
$ cat /etc/cloud/cloud.cfg.d/README 
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.
```

```
$ cat /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg 
network: {config: disabled}
```

## Ubuntu Desktop 24.04 ISO cloud-init

```
$ ls -l /etc/cloud
total 24
drwxr-xr-x 2 root root 4096 Jun  1 11:40 clean.d
-rw-r--r-- 1 root root 3718 Apr  5 16:18 cloud.cfg
drwxr-xr-x 2 root root 4096 Jun  1 11:40 cloud.cfg.d
-rw-r--r-- 1 root root  132 Jun  1 11:44 cloud-init.disabled
-rw-r--r-- 1 root root   16 Jun  1 11:40 ds-identify.cfg
drwxr-xr-x 2 root root 4096 Apr 24 03:49 templates
```

```
$ cat /etc/cloud/cloud-init.disabled 
Disabled by Ubuntu live installer after first boot.
To re-enable cloud-init on this image run:
  sudo cloud-init clean --machine-id
```

```
$ cat /etc/cloud/ds-identify.cfg 
policy: enabled
```

```
$ ls -l /etc/cloud/clean.d/
total 8
-rwxr-xr-x 1 root root 484 Jun  1 11:40 99-installer
-rwxr-xr-x 1 root root 342 Apr 24 03:51 99-installer-use-networkmanager
```

```
$ cat /etc/cloud/clean.d/99-installer
#!/usr/bin/env python3
# Remove live-installer config artifacts when running: sudo cloud-init clean
# Autogenerated by Subiquity: 2024-06-01 18:40:50.910343 UTC


import os

for cfg_file in ["/etc/cloud/cloud-init.disabled", "/etc/cloud/cloud.cfg.d/20-disable-cc-dpkg-grub.cfg", "/etc/cloud/cloud.cfg.d/90-installer-network.cfg", "/etc/cloud/cloud.cfg.d/99-installer.cfg", "/etc/cloud/ds-identify.cfg"]:
    try:
        os.remove(cfg_file)
    except FileNotFoundError:
        pass
```

```
$ cat /etc/cloud/clean.d/99-installer-use-networkmanager 
#!/bin/sh
# Inform clone image creators about strict network-manager cfg for cloud-init
if [ -f /etc/cloud/cloud.cfg.d/99-installer-use-networkmanager.cfg ]; then
  echo "WARNING: cloud-init network config is limited to using network-manager."
  echo "If this is undesirable: rm /etc/cloud/cloud.cfg.d/99-installer-use-networkmanager.cfg"
fi
```

```
$ ls -l /etc/cloud/cloud.cfg.d/
total 28
-rw-r--r-- 1 root root 2071 Mar 27 06:14 05_logging.cfg
-rw-r--r-- 1 root root   28 Jun  1 11:40 20-disable-cc-dpkg-grub.cfg
-rw-r--r-- 1 root root  333 Apr 24 03:49 90_dpkg.cfg
-rw------- 1 root root  117 Jun  1 11:38 90-installer-network.cfg
-rw------- 1 root root  815 Jun  1 11:40 99-installer.cfg
-rw-r--r-- 1 root root   35 Jun  1 11:34 curtin-preserve-sources.cfg
-rw-r--r-- 1 root root  167 Mar 27 06:14 README
```

```
$ cat /etc/cloud/cloud.cfg.d/05_logging.cfg 
## This yaml formatted config file handles setting
## logger information.  The values that are necessary to be set
## are seen at the bottom.  The top '_log' are only used to remove
## redundancy in a syslog and fallback-to-file case.
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
$ cat /etc/cloud/cloud.cfg.d/20-disable-cc-dpkg-grub.cfg 
grub_dpkg:
  enabled: false
```

```
$ cat /etc/cloud/cloud.cfg.d/90_dpkg.cfg 
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, ConfigDrive, OpenNebula, DigitalOcean, Azure, AltCloud, OVF, MAAS, GCE, OpenStack, CloudSigma, SmartOS, Bigstep, Scaleway, AliYun, Ec2, CloudStack, Hetzner, IBMCloud, Oracle, Exoscale, RbxCloud, UpCloud, VMware, Vultr, LXD, NWCS, Akamai, WSL, None ]
```

```
$ sudo cat /etc/cloud/cloud.cfg.d/90-installer-network.cfg 
[sudo] password for automat: 
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp1s0:
      dhcp4: true
  version: 2
```

```
$ sudo cat /etc/cloud/cloud.cfg.d/99-installer.cfg
datasource:
  None:
    metadata:
      instance-id: 8f24aaf6-e801-4314-ab4d-140cf7903665
    userdata_raw: "#cloud-config\ngrowpart:\n  mode: 'off'\nlocale: en_US.UTF-8\n\
      preserve_hostname: true\nresize_rootfs: false\ntimezone: America/Los_Angeles\n\
      users:\n- gecos: automat\n  groups: adm,cdrom,dip,lpadmin,plugdev,sudo,users\n\
      \  lock_passwd: false\n  name: automat\n  passwd: $6$40T70sujp2hUJyd9$IlfKZwMFKEmsGuG.xCYtmO3iUTWqPcg1erpNuaD3qd3xPq9U09ON5J3lZX8zkqAOWOx/IteCJgD3/m8ddLFv.1\n\
      \  shell: /bin/bash\nwrite_files:\n- content: \"Disabled by Ubuntu live installer\
      \ after first boot.\\nTo re-enable cloud-init\\\n    \\ on this image run:\\\
      n  sudo cloud-init clean --machine-id\\n\"\n  defer: true\n  path: /etc/cloud/cloud-init.disabled\n"
datasource_list:
- None
```

```
$ cat /etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg 
apt:
  preserve_sources_list: true
```

```
$ cat /etc/cloud/cloud.cfg.d/README 
# All files with the '.cfg' extension in this directory will be read by
# cloud-init. They are read in lexical order. Later files overwrite values in
# earlier files.
```

References:

Create Ubuntu 22.04 KVM Guest From Cloud Image https://blog.programster.org/create-ubuntu-22-kvm-guest-from-cloud-image

qemu-img Backing Files: A Poor Man's Sanpshot/Rollback: https://dustymabe.com/2015/01/11/qemu-img-backing-files-a-poor-mans-snapshotrollback/

QCOW2 backing files & overlays: https://kashyapc.fedorapeople.org/virt/lc-2012/snapshots-handout.html

Using Cloud Images With KVM https://serverascode.com/2018/06/26/using-cloud-images.html

Cloud-Init - Getting Started https://blog.while-true-do.io/cloud-init-getting-started/

How-To: Make Ubuntu Autoinstall ISO with Cloud-init https://www.pugetsystems.com/labs/hpc/how-to-make-ubuntu-autoinstall-iso-with-cloud-init-2213/

https://austinsnerdythings.com/2021/08/30/how-to-create-a-proxmox-ubuntu-cloud-init-image/

