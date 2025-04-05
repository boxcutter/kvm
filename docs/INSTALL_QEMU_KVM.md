# Install QEMU/KVM on Ubuntu 24.04

Install QEMU/KVM and libvirtd

```
sudo apt-get update
sudo apt-get install qemu-kvm libvirt-daemon-system
# if you want to install images from ISOs with virt-install
sudo apt-get install virtinst
```

Make sure the current user is a member of the libvirt and kvm groups

```
$ sudo adduser $(id -un) libvirt
Adding user '<username>' to group 'libvirt' ...
$ sudo adduser $(id -un) kvm
Adding user '<username>' to group 'kvm' ...
```

Run `virt-host-validate` to check your setup:

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
  QEMU: Checking for device assignment IOMMU support                         : PASS
  QEMU: Checking if IOMMU is enabled by kernel                               : PASS
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

## Create a storage pool for ISOs

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
$ virsh vol-list --pool default --details
$ virsh pool-info iso

$ sudo ls -ld /var/lib/libvirt/iso
drwx--x--x 2 root root 4096 Nov 12 08:41 /var/lib/libvirt/iso

# Install curl
$ sudo apt-get update
$ sudo apt-get install ca-certificates curl

$ sudo curl \
    -L https://releases.ubuntu.com/20.04.6/ubuntu-20.04.6-live-server-amd64.iso \
    -o /var/lib/libvirt/iso/ubuntu-20.04.6-live-server-amd64.iso

$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-20.04.6-live-server-amd64.iso
b8f31413336b9393ad5d8ef0282717b2ab19f007df2e9ed5196c13d8f9153c8b *ubuntu-20.04.6-live-server-amd64.iso

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

$ sudo curl \
    -L https://releases.ubuntu.com/20.04.6/ubuntu-20.04.6-desktop-amd64.iso \
    -o /var/lib/libvirt/iso/ubuntu-20.04.6-desktop-amd64.iso
$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-20.04.6-desktop-amd64.iso
510ce77afcb9537f198bc7daa0e5b503b6e67aaed68146943c231baeaab94df1 *ubuntu-20.04.6-desktop-amd64.iso

$ sudo curl \
    -L https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-desktop-amd64.iso \
    -o /var/lib/libvirt/iso/ubuntu-22.04.4-desktop-amd64.iso
$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-22.04.4-desktop-amd64.iso
071d5a534c1a2d61d64c6599c47c992c778e08b054daecc2540d57929e4ab1fd *ubuntu-22.04.4-desktop-amd64.iso

$ sudo curl \
    -L https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso \
    -o /var/lib/libvirt/iso/ubuntu-24.04-desktop-amd64.iso
$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-24.04-desktop-amd64.iso
81fae9cc21e2b1e3a9a4526c7dad3131b668e346c580702235ad4d02645d9455 *ubuntu-24.04-desktop-amd64.iso
```

## Create a storage pool for images

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

# Verify the storage pool is listed
$ virsh pool-list --all
$ virsh vol-list --pool default --details
```

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
$ virsh vol-list --pool boot-scratch --details
```
