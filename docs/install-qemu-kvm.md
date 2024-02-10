# Install QEMU/KVM on Ubuntu 22.04

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
virt-host-validate qemu
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

## Configure bridged networking

All the networking options for kvm are just different configurations for a virtual networking
switch, also known as a bridge network interface.

The default network created when libvirt is used is called `default` and uses NAT. It normally
is configured to use a bridge network interface called `virbr0`. When a virtual machine is
on a NAT network, it is on a separate subnet that prevents outside access to the VM directly,
nwhile the VM itself can access any network the host can access.

With bridged networking, the VM will be on the same network as the host. It can be accessed
by all computers on your host network as if it were another computer directly connected to
the same network.

### Determine how the networking is configured on Ubuntu

Ubuntu has multiple methods for persisting network configurations, so first you need to
determine how the networking on your machine is configured.

On Ubuntu, determine if the host interface is managed by `systemd-networkd` or `NetworkManager`.
Usually if you are using Ubuntu Desktop, it's `NetworkManager`, and if you are using
Ubuntu Server, it's `systemd-networkd`, but it can vary.

Running `networkctl` will tell you is `systemd-networkd` is running and if an interface
is being managed. The default configuration on Ubuntu Desktop should show that
`systemd-networkd` is not running and the interfaces are not being managed (by `systemd-networkd`).

```
$ networkctl
WARNING: systemd-networkd is not running, output will be incomplete.

IDX LINK      TYPE     OPERATIONAL SETUP    
  1 lo        loopback n/a         unmanaged
  2 eno1      ether    n/a         unmanaged
  3 wlp0s20f3 wlan     n/a         unmanaged
  4 virbr0    bridge   n/a         unmanaged
  5 docker0   bridge   n/a         unmanaged

5 links listed.
```

By comparison, if `systemd-networkd` is running and interfaces are being managed, the
output of `networkctl` looks more like this:

```
$ networkctl
IDX LINK  TYPE     OPERATIONAL SETUP
  1 lo    loopback carrier     unmanaged
  2 ens33 ether    routable    configured

2 links listed.
```

You can check to see if NetworkManager is being used by using `nmcli`. If the network
interfaces are being managed by NetworkManager, the output will look something like
this:

```
$ nmcli general
STATE      CONNECTIVITY  WIFI-HW  WIFI     WWAN-HW  WWAN    
connected  full          enabled  enabled  enabled  enabled

$ nmcli connection
NAME                UUID                                  TYPE      DEVICE  
Wired connection 1  5297a82f-7244-31f3-9dad-c3fb49be0b33  ethernet  eno1    
docker0             80651a82-b1af-4ed7-a4bb-e0a802d6f012  bridge    docker0 
virbr0              d0da1989-df49-44dc-9c48-aa3c978fbb90  bridge    virbr0
```

But you're not done yet, you also need to check if netplan is being used to render
configurations in `systemd-networkd` or `NetworkManager`. In Ubuntu 24.04, there will
be a command called `netplan status` to check this. As of this writing, you are unlikely
to be using this, so instead the best way to check is to see if there are configuration
files in `/etc/netplan`. If `netplan` is being used on your system, it's probably
easiest to add the configuration for the bridge configuration through netplan.

Here's an example of a `systemd-networkd` configuration managed by `netplan`. It may
or may not include a `renderer` stanza that says `renderer: networkd`, because it is
the default:

```
$ ls /etc/netplan
00-installer-config.yaml
$ cat /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens33:
      dhcp4: true
  version: 2
```

On the other hand, if a `NetworkManager` configuration is being managed by `netplan`,
it will include a `renderer` stanza that says `renderer: NetworkManager`. It's not
unusual for there to be any configuration in the netplan file, because currently,
NetworkManager isn't very well integrated into netplan on Ubuntu. You can't use
`netplan try` to experiment with new configurations, for example.

```
$ ls /etc/netplan/
01-network-manager-all.yaml
$ cat /etc/netplan/01-network-manager-all.yaml 
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
```
