# Install QEMU/KVM on Ubuntu 22.04

Install QEMU/KVM and libvirtd

```
sudo apt-get install update
sudo apt-get install qemu-kvm libvirt-daemon-system
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
