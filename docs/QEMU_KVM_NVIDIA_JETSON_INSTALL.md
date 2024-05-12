# QEMU/KVM Install for NVDIA Jetson Platform

Install QEMU/KVM and libvirtd 

```bash
apt-get update
sudo apt-get update
sudo apt-get install qemu-kvm libvirt-daemon-system
# if you want to install images from ISOs with virt-install
sudo apt-get install virtinst
```

Make sure the current user is a member of the libvirt and kvm groups

```bash
$ sudo adduser $(id -un) libvirt
Adding user '<username>' to group 'libvirt' ...
$ sudo adduser $(id -un) kvm
Adding user '<username>' to group 'kvm' ...
```

Run `virt-host-validate` to check the setup:

```bash
$ virt-host-validate qemu
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : WARN (Load the 'vhost_net' module to improve performance of virtio networking)
  QEMU: Checking if device /dev/net/tun exists                               : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : WARN (Enable 'devices' in kernel Kconfig file or mount/enable cgroup controller in your system)
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for device assignment IOMMU support                         : WARN (Unknown if this platform has IOMMU support)
  QEMU: Checking for secure guest support                                    : WARN (Unknown if this platform has Secure Guest support)

# Enable cgroup controllers
sudo cp /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.orig
sudo vi /boot/extlinux/extlinux.conf
# Add cgroup statements to the end of APPEND statement
APPEND root=/dev/sda1 rw cgroup_enable=memory,cgroup_enable=cpu,cgroup_enable=devices cgroup_memory=1


sudo vi /etc/default/grub
# Add or modify the GRUB_CMDLINE_LINUX line to include the necessary cgroup settings
GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
# Update GRUB and reboot
sudo update-grub
sudo reboot
```

Reboot to restart the QEMU/KVM daemon

```bash
sudo restart
```
