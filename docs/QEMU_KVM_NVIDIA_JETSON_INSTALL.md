# QEMU/KVM Install for the NVDIA Jetson Platform

## Setup

### Install QEMU/KVM and libvirtd 

```bash
apt-get update
sudo apt-get update
sudo apt-get install qemu-kvm libvirt-daemon-system
# if you want to install images from ISOs with virt-install
sudo apt-get install virtinst
# Ubuntu 22.04 missing dependency
sudo apt-get install seabios
```

### Make sure the current user is a member of the libvirt and kvm groups

```bash
$ sudo adduser $(id -un) libvirt
Adding user '<username>' to group 'libvirt' ...
$ sudo adduser $(id -un) kvm
Adding user '<username>' to group 'kvm' ...
```

### Run `virt-host-validate` to check the setup:

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

# The vhost_net module does not appear to be present in the default Linux for Tegra kernel

# There's no grub on arm64, boot options are controlled by /boot/extlinux/extlinux.conf
# But doesn't appear that it's possible to enable devices support
# sudo cp /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.orig
# APPEND root=/dev/sda1 rw cgroup_enable=memory,cgroup_enable=cpu,cgroup_enable=devices cgroup_memory=1
```

### Reboot to restart the QEMU/KVM daemon

```bash
sudo restart
```

### Configure bridged networking

Out of the box, Linux for Tegra doesn't come configured with netplan,
is configured with a Linux Desktop, and uses NetManager directly

```
$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
can0             DOWN           <NOARP,ECHO> 
can1             DOWN           <NOARP,ECHO> 
wlan0            UP             b4:8c:9d:1c:59:cb <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth0             UP             48:b0:2d:dc:cc:a5 <BROADCAST,MULTICAST,UP,LOWER_UP> 
l4tbr0           DOWN           3e:c7:e7:79:f3:87 <BROADCAST,MULTICAST> 
usb0             DOWN           4a:cc:c0:ee:72:85 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
usb1             DOWN           4a:cc:c0:ee:72:87 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
virbr0           DOWN           52:54:00:db:7e:78 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
docker0          DOWN           02:42:92:48:71:3d <NO-CARRIER,BROADCAST,MULTICAST,UP>

$ nmcli connection show
NAME                UUID                                  TYPE      DEVICE  
Wired connection 1  bde1a0a0-8fd9-3eb3-acb5-17fe609b124e  ethernet  eth0    
Dreamfall           266ae331-63c7-4f90-9f8b-68ce24868245  wifi      wlan0   
docker0             1f351718-5833-46fe-a8ad-ba119dd90723  bridge    docker0 
virbr0              bde3a162-949a-4665-a88f-fe2e65e5e07b  bridge    virbr0
```

```
# Create the bridge br0 with STP disabled to avoid the bridge being advertised on the network
$ sudo nmcli connection add type bridge ifname br0 stp no
# Swing the ethernet interface to the bridge
$ sudo nmcli connection add type bridge-slave ifname eth0 master br0
```

```
# Bring the existing connection down
$ sudo nmcli connection down 'Wired connection 1'
# Bring the new bridge up
$ sudo nmcli connection up bridge-br0
$ sudo nmcli connection up bridge-slave-eth0

$ nmcli c
NAME                UUID                                  TYPE      DEVICE  
bridge-br0          27c2851c-e0d1-4606-91ba-526c79316273  bridge    br0     
Dreamfall           266ae331-63c7-4f90-9f8b-68ce24868245  wifi      wlan0   
docker0             1f351718-5833-46fe-a8ad-ba119dd90723  bridge    docker0 
virbr0              bde3a162-949a-4665-a88f-fe2e65e5e07b  bridge    virbr0  
bridge-slave-eth0   8be31a75-923c-47ed-8256-bc9d82d4aa12  ethernet  eth0    
Wired connection 1  bde1a0a0-8fd9-3eb3-acb5-17fe609b124e  ethernet  --  
```

Because the default NVIDIA install installs Docker, sdd bridged
interface to DOCKER-USER chain
```
# https://serverfault.com/questions/963759/docker-breaks-libvirt-bridge-network
# https://docs.docker.com/network/packet-filtering-firewalls/
sudo iptables -I DOCKER-USER -i br0 -o br0 -j ACCEPT
# verify chain
sudo iptables -L DOCKER-USER -v -n
# verify it works, then save the rules
sudo apt-get update
sudo apt-get install iptables-persistent
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
```

### Create a definition for the bridge network in libvirt

```
vi /tmp/host-network.xml
<network>
  <name>host-network</name>
  <forward mode="bridge"/>
  <bridge name="br0" />
</network>

sudo virsh net-define /tmp/host-network.xml
sudo virsh net-start host-network
sudo virsh net-autostart host-network
sudo virsh net-list --all
$ sudo virsh net-list --all
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
Pool iso started

# Turn on autostart
$ virsh pool-autostart iso
Pool iso marked as autostarted

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

$ sudo curl \
    -L https://cdimage.ubuntu.com/releases/22.04.4/release/ubuntu-22.04.4-live-server-arm64.iso \
    -o /var/lib/libvirt/iso/ubuntu-22.04.4-live-server-arm64.iso

$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-22.04.4-live-server-arm64.iso
74b8a9f71288ae0ac79075c2793a0284ef9b9729a3dcf41b693d95d724622b65 *ubuntu-22.04.4-live-server-arm64.iso

$ sudo curl \
    -L https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04-live-server-arm64.iso \
    -o /var/lib/libvirt/iso/ubuntu-24.04-live-server-arm64.iso
$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-24.04-live-server-arm64.iso
d2d9986ada3864666e36a57634dfc97d17ad921fa44c56eeaca801e7dab08ad7 *ubuntu-24.04-live-server-arm64.iso
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
Pool default built

# Start the storage pool
$ virsh pool-start default
Pool default started

# Turn on autostart
$ virsh pool-autostart default
Pool default marked as autostarted

$ virsh pool-list --all
 Name      State    Autostart
-------------------------------
 default   active   yes
 iso       active   yes
```

### Create a volume in a storage pool and start the install

NOTE: When you install Ubuntu interactively and choose default partitioning, only
HALF the disk space is used by default: https://bugs.launchpad.net/subiquity/+bug/1907128

```

$ virsh domblklist ubuntu-image
 Target   Source
--------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-image-1.qcow2
 sda      -

$ virsh change-media ubuntu-image sda --eject
error: The disk device 'sda' doesn't have media

$ virsh detach-disk ubuntu-image sda --config
Disk detached successfully

$ virsh domblklist ubuntu-image
 Target   Source
--------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-image-1.qcow2

# Install acpi or qemu-guest-agent in the vm so that
# 'virsh shutdown <image>' works
$ sudo apt-get update
$ sudo apt-get install qemu-guest-agent
```

### Installing Ubuntu 24.04 Server on a graphical head

NOTE: When you install Ubuntu interactively and choose default partitioning, only
HALF the disk space is used by default: https://bugs.launchpad.net/subiquity/+bug/1907128

```
# Be patient, this will take awhile to display anything
virt-install \
  --connect qemu:///system \
  --name ubuntu-server \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/ubuntu-22.04.4-live-server-arm64.iso \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk pool=default,size=50,bus=virtio,format=qcow2 \
  --network network=host-network,model=virtio \
  --graphics spice \
  --debug

$ virsh vncdisplay ubuntu-server
:0
$ virsh dumpxml ubuntu-server | grep "graphics type='vnc'"
    <graphics type='vnc' port='5900' autoport='yes' listen='0.0.0.0'>

# vnc to server on port  to complete install
# Get the IP address of the default host interface
ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
# Use a vnc client to connect to `vnc://<host_ip>:5900`
# When the install is complete the VM will be shut down

# enable serial service in VM
sudo systemctl enable --now serial-getty@ttyS0.service


virsh destroy ubuntu-server
virsh undefine ubuntu-server --nvram --remove-all-storage
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
  --network bridge=br0,model=virtio \
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

# Reconfigure VNC
virsh edit ubuntu-desktop-2404
<graphics type='vnc' port='-1' autoport='yes' listen='127.0.0.1' passwd='foobar'/>
<graphics type='none'/>
virsh restart ubuntu-desktop-2404

# Optional - Enable serial console access
# https://ravada.readthedocs.io/en/latest/docs/config_console.html
# enable serial service in VM
sudo systemctl enable --now serial-getty@ttyS0.service

# Optional - user setup
# Add User
# Settings > Power > Blank Screen: None
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

### Removing and deleting a VM
```
$ virsh shutdown ubuntu-image
# "Force off" the VM - doesn't actually remove the VM
$ virsh destroy ubuntu-image
# Optionally add --remove-all-storage to remove the storage pool
$ virsh undefine ubuntu-image --nvram
$ virsh vol-delete --pool default ubuntu-image.qcow2
Vol ubuntu-image.qcow2 deleted
```
