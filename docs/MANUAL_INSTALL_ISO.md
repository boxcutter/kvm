# Installing an OS from an ISO without automation

## Setup

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

$ sudo curl \
    -L https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso \
    -o /var/lib/libvirt/iso/ubuntu-22.04.3-live-server-amd64.iso

$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-22.04.3-live-server-amd64.iso
a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd  /var/lib/libvirt/iso/ubuntu-22.04.3-live-server-amd64.iso

$ sudo curl \
    -L https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso \
    -o /var/lib/libvirt/iso/ubuntu-24.04-live-server-amd64.iso
$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-24.04-live-server-amd64.iso
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

# Turn on autostart
$ virsh pool-autostart default
Pool default marked as autostarted

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
  --name ubuntu-image \
  --memory 4096 \
  --vcpus 2 \
  --disk pool=default,size=20,format=qcow2 \
  --cdrom /var/lib/libvirt/iso/ubuntu-22.04.3-live-server-amd64.iso \
  --os-variant ubuntu22.04 \
  --network network=default,model=virtio \
  --boot uefi \
  --debug \
  --noreboot

# Install acpi or qemu-guest-agent in the vm so that
# 'virsh shutdown <image>' works
$ sudo apt-get update
$ sudo apt-get install qemu-guest-agent
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
