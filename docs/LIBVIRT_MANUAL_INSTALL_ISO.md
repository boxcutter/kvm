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

### Configure bridged networking - Ubuntu Desktop

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

### Configure bridged networking - Ubuntu Server

```bash
$ sudo netplan get

network:
  version: 2
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
  ethernets:
    enp1s0:
      dhcp4: false
      dhcp6: false
      # Marks the interface as optional during boot, so the system won't
      # wait for it to be up, which it will never be because it is 
      optional: true
  bridges:
    br0:
      interfaces: [enp1s0]
      dhcp4: true
      dhcp6: false
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
br0              UP             192.168.107.166/24 
```

```
$ sudo netplan get

network:
  version: 2
  ethernets:
    enp1s0:
      optional: true
      dhcp4: false
      dhcp6: false
  bridges:
    br0:
      dhcp4: true
      dhcp6: false
      accept-ra: false
      interfaces:
      - enp1s0
      parameters:
        stp: false
      link-local: []
```

### Create a definition for the bridge network in libvirt

```
cat <<EOF > /tmp/host-network.xml
<network>
  <name>host-network</name>
  <forward mode="bridge"/>
  <bridge name="br0" />
</network>
EOF

sudo virsh net-define /tmp/host-network.xml
sudo virsh net-start host-network
sudo virsh net-autostart host-network
sudo virsh net-list --all
```

## Installing an OS from an ISO without automation

### Create a storage pool for ISOs
Create a storage pool for your ISOs, so that virsh has permission to access them.
By default a clean KVM install does not define any storage pools.

```
virsh pool-define-as iso dir --target "/var/lib/libvirt/iso"
virsh pool-build iso
virsh pool-start iso
virsh pool-autostart iso

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
virsh pool-define-as default dir --target "/var/lib/libvirt/images"
virsh pool-build default
virsh pool-start default
virsh pool-autostart default
```

# Pool for storing temporary cloud-init boot images
```
virsh pool-define-as \
    --name boot-scratch \
    --type dir \
    --target /var/lib/libvirt/boot
virsh pool-build boot-scratch
virsh pool-start boot-scratch
virsh pool-autostart boot-scratch
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

### Ubuntu Server 2404 VM

```
mkdir ~/ubuntu-server-2404
cd ~/ubuntu-server-2404
curl -LO https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
qemu-img info noble-server-cloudimg-amd64.img

sudo qemu-img convert \
  -f qcow2 \
  -O qcow2 \
  noble-server-cloudimg-amd64.img \
  /var/lib/libvirt/images/ubuntu-server-2404.qcow2
sudo qemu-img resize \
  -f qcow2 \
  /var/lib/libvirt/images/ubuntu-server-2404.qcow2 \
  64G

touch network-config

cat >meta-data <<EOF
instance-id: ubuntu-server-2404
local-hostname: ubuntu-server-2404
EOF

cat >user-data <<EOF
#cloud-config
hostname: ubuntu-server-2404
users:
  - name: automat
    uid: 63112
    primary_group: users
    groups: users
    shell: /bin/bash
    plain_text_passwd: superseekret
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
chpasswd: { expire: False }
ssh_pwauth: True
package_update: False
package_upgrade: false
packages:
  - qemu-guest-agent
growpart:
  mode: auto
  devices: ['/']
power_state:
  mode: reboot
EOF

sudo apt-get update
sudo apt-get install genisoimage
genisoimage \
    -input-charset utf-8 \
    -output ubuntu-server-2404-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp ubuntu-server-2404-cloud-init.img /var/lib/libvirt/boot/ubuntu-server-2404-cloud-init.iso
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2404 \
  --boot uefi \
  --memory 3092 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2404.qcow2 \
  --disk /var/lib/libvirt/boot/ubuntu-server-2404-cloud-init.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2404

$ cloud-init status
status: done

# Verify networking is working
$ ip -br a

# Check to make sure cloud-init is greater than 23.4
$ cloud-init --version
/usr/bin/cloud-init 24.1.3-0ubuntu1~22.04.1

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ cloud-init status
status: disabled

$ sudo shutdown -h now

$ virsh domblklist ubuntu-server-2404
$ virsh change-media ubuntu-server-2404 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/ubuntu-server-2404-cloud-init.iso
```

```
$ virsh snapshot-create-as --domain ubuntu-server-2404 --name clean --description "Initial install"
$ virsh snapshot-list ubuntu-server-2404
$ virsh snapshot-revert ubuntu-server-2404 clean
$ virsh snapshot-delete ubuntu-server-2404 clean

$ virsh shutdown ubuntu-server-2404
$ virsh undefine ubuntu-server-2404 --nvram --remove-all-storage
```

```
virsh start ubuntu-server-2404
```
