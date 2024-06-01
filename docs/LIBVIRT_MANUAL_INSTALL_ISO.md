# Installing an OS from an ISO without automation

## Setup

### Install QEMU/KVM and libvirtd

```
sudo apt-get update
sudo apt-get install qemu-kvm libvirt-daemon-system
# if you want to install images from ISOs with virt-install
sudo apt-get install virtinst
```

### Make sure the current user is a member of the libvirt and kvm groups

```
$ sudo adduser $(id -un) libvirt
Adding user '<username>' to group 'libvirt' ...
$ sudo adduser $(id -un) kvm
Adding user '<username>' to group 'kvm' ...
```

### Run `virt-host-validate` to check your setup:

```
$ virt-host-validate qemu
  QEMU: Checking for hardware virtualization                                 : PASS
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : PASS
  QEMU: Checking if device /dev/net/tun exists                               : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : WARN (Enable 'devices' in kernel Kconfig file or mount/enable cgroup controller in your system)
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for device assignment IOMMU support                         : WARN (No ACPI DMAR table found, IOMMU either disabled in BIOS or not supported by this hardware platform)
  QEMU: Checking for secure guest support                                    : WARN (Unknown if this platform has Secure Guest support)
```

X86_64-based machines will likely display a warning about cgroup devices controller
support not being enabled. This allos you to apply resource management to virtual
machines. For more information refer to [this doc](https://libvirt.org/cgroups.html).
To add cgroup 'devices' controller support, edit `/etc/default/grub`
and change the line that looks like `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"`
to:
```
# GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on systemd.unified_cgroup_hierarchy=0"
```

And then run `update-grub` to update your boot options:

```
sudo update-grub
```

Reboot and then everything in `virt-host-validate` should pass. The tool
can't validate secure guest support on Intel chips, only on AMD or IBM
processors, so the warning is accurate there: https://stackoverflow.com/questions/65207563/qemu-warn-unknown-if-this-platform-has-secure-guest-support

Also make sure that the packages with the UEFI firmware are present - on Ubuntu these should be
installed automatically when `qemu-kvm` is installed:
```
# Open Virtual Machine Firmware for X86-64 processors
# Files are in /usr/share/OVMF
sudo apt-get install ovmf
# ARM Architecture Virtual Machine firmware
# Files are in /usr/share/AAVMF
sudo apt-get install qemu-efi-aarch64
```

### Reboot to restart the QEMU/KVM daemon

```bash
sudo reboot
```

### Configure bridged networking

```bash
$ sudo netplan get

network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp1s0:
      dhcp4: true

$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
enp1s0           UP             52:54:00:06:be:23 <BROADCAST,MULTICAST,UP,LOWER_UP>
virbr0           DOWN           52:54:00:be:01:10 <NO-CARRIER,BROADCAST,MULTICAST,UP>
```

```
vi /etc/netplan/host-bridge.yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp1s0:
      dhcp4: false
  bridges:
    br0:
      interfaces: [enp1s0]
      dhcp4: yes
      accept-ra: false
      link-local: []
      parameters:
        stp: false
```

```
$ sudo netplan --debug apply
$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp1s0           UP
virbr0           DOWN           192.168.122.1/24
br0              UP             192.168.107.166/24 fda2:8d37:bed8:93ee:fae5:b754:611f:1b75/64 fda2:8d37:bed8:93ee:4455:46ff:fee4:1d6f/64 fe80::4455:46ff:fee4:1d6f/64
```

```
$ sudo netplan get

network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp1s0:
      dhcp4: false
  bridges:
    br0:
      dhcp4: true
      accept-ra: false
      interfaces:
      - enp1s0
      parameters:
        stp: false
      link-local: []
```

### Create a definition for the bridge network in libvirt

```
vi /tmp/host-network.xml
<network>
  <name>host-network</name>
  <forward mode="bridge"/>
  <bridge name="br0" />
</network>

virsh net-define /tmp/host-network.xml
virsh net-start host-network
virsh net-autostart host-network
virsh net-list --all
$ virsh net-list --all
 Name           State    Autostart   Persistent
-------------------------------------------------
 default        active   yes         yes
 host-network   active   yes         yes
```

## Installing an OS from an ISO without automation

### Create a storage pool for ISOs
Create a storage pool for your ISOs, so that virsh has permission to access them.
By default a clean KVM install does not define any storage pools.

```
# Create the storage pool definition
$ virsh pool-define-as \
    --name iso \
    --type dir \
    --target /var/lib/libvirt/iso
Pool iso defined

# Create the local directory
$ virsh pool-build iso
# Start the storage pool
$ virsh pool-start iso
# Turn on autostart
$ virsh pool-autostart iso

# Verify the storage pool is listed
$ virsh pool-list --all
 Name   State    Autostart
----------------------------
 iso    active   yes

$ virsh vol-list --pool iso --details
 Name   Path   Type   Capacity   Allocation
---------------------------------------------

# Verify the storage pool configuration
$ virsh pool-info iso
Name:           iso
UUID:           7de2281d-2fda-41e4-900f-3819ba3407e7
State:          running
Persistent:     yes
Autostart:      yes
Capacity:       960.65 GiB
Allocation:     12.49 GiB
Available:      948.16 GiB

$ sudo ls -ld /var/lib/libvirt/iso
drwx--x--x 2 root root 4096 Nov 12 08:41 /var/lib/libvirt/iso

# Install curl
$ sudo apt-get update
$ sudo apt-get install ca-certificates curl

$ sudo curl \
    -L https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso \
    -o /var/lib/libvirt/iso/ubuntu-22.04.4-live-server-amd64.iso

$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-22.04.4-live-server-amd64.iso
45f873de9f8cb637345d6e66a583762730bbea30277ef7b32c9c3bd6700a32b2 *ubuntu-22.04.4-live-server-amd64.iso

$ sudo curl \
    -L https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso \
    -o /var/lib/libvirt/iso/ubuntu-24.04-live-server-amd64.iso
$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-24.04-live-server-amd64.iso
8762f7e74e4d64d72fceb5f70682e6b069932deedb4949c6975d0f0fe0a91be3 *ubuntu-24.04-live-server-amd64.iso
```

### Create a storage pool for images

```
# Create the storage pool definition
$ virsh pool-define-as \
    --name default \
    --type dir \
    --target /var/lib/libvirt/images

# Create the local directory
$ virsh pool-build default
# Start the storage pool
$ virsh pool-start default
# Turn on autostart
$ virsh pool-autostart default

$ virsh pool-list --all
 Name      State    Autostart
-------------------------------
 default   active   yes
 iso       active   yes
```

### Installing Ubuntu 24.04 Server on a graphical head

NOTE: When you install Ubuntu interactively and choose default partitioning, only
HALF the disk space is used by default: https://bugs.launchpad.net/subiquity/+bug/1907128

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2404 \
  --memory 4096 \
  --vcpus 2 \
  --disk pool=default,size=20,format=qcow2 \
  --cdrom /var/lib/libvirt/iso/ubuntu-24.04-live-server-amd64.iso \
  --os-variant ubuntu24.04 \
  --network network=default,model=virtio \
  --boot uefi \
  --debug \
  --noreboot

# Install acpi or qemu-guest-agent in the vm so that
# 'virsh shutdown <image>' works
$ sudo apt-get update
$ sudo apt-get install qemu-guest-agent

# enable serial service in VM
sudo systemctl enable --now serial-getty@ttyS0.service

# Extend partition to use all availabe disk space
# Identify the logical volume
sudo vgdisplay
sudo lvdisplay
# Extend the logical volume
# Replace /dev/ubuntu-vg/ubuntu-lv with your actual volume group and logical volume names.
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
# Resize the filesystem
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
# Verify the changes
df -h

# Optional - user setup
# passwordless sudo
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/dont-prompt-$USER-for-sudo-password"

# Snapshots
# Named snapshot
virsh snapshot-create-as --domain ubuntu-server-2404 --name clean --description "Initial install"
# Nameless snapshot
virsh snapshot-create ubuntu-server-2404
virsh snapshot-list ubuntu-server-2404
virsh snapshot-revert ubuntu-server-2404 <name>
virsh snapshot-delete ubuntu-server-2404 <name>

virsh destroy ubuntu-server-2404
virsh undefine ubuntu-server-2404 --nvram --remove-all-storage
```

### Installing Ubuntu 24.04 Server on a headless Ubuntu Server using VNC

NOTE: When you install Ubuntu interactively and choose default partitioning, only
HALF the disk space is used by default: https://bugs.launchpad.net/subiquity/+bug/1907128

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2404 \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/ubuntu-24.04-live-server-amd64.iso \
  --memory 16384 \
  --vcpus 4 \
  --os-variant ubuntu20.04 \
  --disk pool=default,size=50,bus=virtio,format=qcow2 \
  --network network=host-network,model=virtio \
  --graphics vnc,listen=0.0.0.0,password=foobar \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug

$ virsh vncdisplay ubuntu-server-2404
:0
$ virsh dumpxml ubuntu-server-2404 | grep "graphics type='vnc'"
    <graphics type='vnc' port='5900' autoport='yes' listen='0.0.0.0'>

# vnc to server on port  to complete install
# Get the IP address of the default host interface
ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
# Use a vnc client to connect to `vnc://<host_ip>:5900`
# When the install is complete the VM will be shut down

# Restart the VM and login
virsh start ubuntu-server-2404

# Install acpi or qemu-guest-agent in the vm so that
# 'virsh shutdown <image>' works
$ sudo apt-get update
$ sudo apt-get install qemu-guest-agent

# enable serial service in VM
sudo systemctl enable --now serial-getty@ttyS0.service

# Extend partition to use all availabe disk space
# Identify the logical volume
sudo vgdisplay
sudo lvdisplay
# Extend the logical volume
# Replace /dev/ubuntu-vg/ubuntu-lv with your actual volume group and logical volume names.
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
# Resize the filesystem
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
# Verify the changes
df -h

# Optional - user setup
# passwordless sudo
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/dont-prompt-$USER-for-sudo-password"

# Snapshots
# Named snapshot
virsh snapshot-create-as --domain ubuntu-server-2404 --name clean --description "Initial install"
# Nameless snapshot
virsh snapshot-create ubuntu-server-2404
virsh snapshot-list ubuntu-server-2404
virsh snapshot-revert ubuntu-server-2404 <name>
virsh snapshot-delete ubuntu-server-2404 <name>


virsh destroy ubuntu-server-2404
virsh undefine ubuntu-server-2404 --nvram --remove-all-storage
```

### Installing Ubuntu 24.04 Desktop on a headless Ubuntu Server using VNC

```
virsh vol-create-as default ubuntu-desktop-2404.qcow2 50G --format qcow2

virt-install \
  --connect qemu:///system \
  --name ubuntu-desktop-2404 \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/ubuntu-24.04-desktop-amd64.iso \
  --memory 16384 \
  --vcpus 4 \
  --os-variant ubuntu22.04 \
  --disk vol=default/ubuntu-desktop-2404.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --graphics vnc,listen=0.0.0.0,password=foobar \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug

$ virsh vncdisplay ubuntu-desktop-2404
:0
$ virsh dumpxml ubuntu-desktop-2404 | grep "graphics type='vnc'"
    <graphics type='vnc' port='5900' autoport='yes' listen='0.0.0.0'>

# vnc to server on port  to complete install
# Get the IP address of the default host interface
ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
# Use a vnc client to connect to `vnc://<host_ip>:5900`
# When the install is complete the VM will be shut down

$ virsh domblklist ubuntu-desktop-2404
 Target   Source
---------------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-desktop-2404.qcow2
 sda      /var/lib/libvirt/iso/ubuntu-24.04-desktop-amd64.iso

$ virsh change-media ubuntu-desktop-2404 sda --eject
Successfully ejected media.

# Reconfigure VNC
virsh edit ubuntu-desktop-2404
<graphics type='vnc' port='-1' autoport='yes' listen='127.0.0.1' passwd='foobar'/>
<graphics type='none'/>
virsh restart ubuntu-desktop-2404

$ virsh start ubuntu-desktop-2404

# Optional - Enable serial console access
# https://ravada.readthedocs.io/en/latest/docs/config_console.html
# enable serial service in VM
sudo systemctl enable --now serial-getty@ttyS0.service

# Install acpi or qemu-guest-agent in the vm so that
# 'virsh shutdown <image>' works
$ sudo apt-get update
$ sudo apt-get install qemu-guest-agent

# Optional - user setup
# Add User
# Settings > Power > Blank Screen: None
# Prevent the screen from blanking
gsettings set org.gnome.desktop.session idle-delay 0
# Prevent the screen from locking
gsettings set org.gnome.desktop.screensaver lock-enabled false
# Display Resolution 1440 x 900 (16:10)
# passwordless sudo
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/dont-prompt-$USER-for-sudo-password"

# Snapshots
# Named snapshot
virsh snapshot-create-as --domain ubuntu-desktop-2404 --name clean --description "Initial install"
# Nameless snapshot
virsh snapshot-create ubuntu-desktop-2404 
virsh snapshot-list ubuntu-desktop-2404
virsh snapshot-revert ubuntu-desktop-2404 <name>
virsh snapshot-delete ubuntu-desktop-2404 <name>

virsh destroy ubuntu-desktop-2404
virsh undefine ubuntu-desktop-2404 --nvram --remove-all-storage
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

https://www.pugetsystems.com/labs/hpc/ubuntu-22-04-server-autoinstall-iso/
