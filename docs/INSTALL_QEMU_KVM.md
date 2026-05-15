# Install QEMU/KVM on Ubuntu 26.04

Install QEMU/KVM and libvirtd

```
sudo apt-get update
# Ubuntu 26.04 split qemu-kvm into qemu-system-x86-hwe and qemu-system-x86.
# The hwe variant is updated more frequently, every 6 months
# https://ubuntu.com/server/docs/how-to/virtualisation/virt-hwe/
sudo apt-get install qemu-system-hwe libvirt-daemon-system-hwe
# if you want to install images from ISOs with virt-install
sudo apt-get install virtinst
```

Make sure the current user is a member of the libvirt and kvm groups

```
# Gives permission to manage virtual machines with virsh
$ sudo adduser $(id -un) libvirt
Adding user '<username>' to group 'libvirt' ...
# Gives permission to access the /dev/kvm device
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
support not being enabled.
`QEMU: Checking for cgroup 'devices' controller support : WARN`
Ignore this. Modern Ubuntu uses cgroup v2, which does
not have a separate devices controller to enbale like cgroup v1 did.
`QEMU: Checking for cgroup 'devices' controller support : WARN`

If you see a warning secure guest support, you probably have an older CPU.
Older CPUs don't have this functionality. This is not required for normal
KVM/QEMU virtualization.

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

## Create a default storage pool for virtual machine images

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
```
