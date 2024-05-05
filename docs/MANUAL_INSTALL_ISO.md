# Installing an OS from an ISO without automation

## Create a storage pool for ISOs
Create a storage pool for your ISOs, so that virsh has permission to access them.
By default a clean KVM install does not define any storage pools.

```
# Create the storage pool definition
$ virsh pool-define-as \
    --name iso \
    --type dir \
    --target /var/lib/libvirt/iso
Pool iso defined

# Verify the storage pool is listed
$ virsh pool-list --all
 Name   State      Autostart
------------------------------
 iso    inactive   no

# Create the local directory
$ virsh pool-build iso
Pool iso built

$ sudo ls -la /var/lib/libvirt/iso
total 8
drwx--x--x  2 root root 4096 Oct  7 14:47 .
drwxr-xr-x 10 root root 4096 Oct  7 14:47 ..

# Start the storage pool
$ virsh pool-start iso
Pool iso started

$ virsh vol-list --pool iso --details
 Name   Path   Type   Capacity   Allocation
---------------------------------------------

$ virsh pool-list --all
 Name   State    Autostart
----------------------------
 iso    active   no

# Turn on autostart
$ virsh pool-autostart iso
Pool iso marked as autostarted

$ virsh pool-list --all
 Name   State    Autostart
----------------------------
 iso    active   yes

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

## Create a storage pool for images

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

$ virsh pool-list --all
 Name      State    Autostart
-------------------------------
 default   active   no
 iso       active   yes

# Turn on autostart
$ virsh pool-autostart default
Pool default marked as autostarted

$ virsh pool-list --all
 Name      State    Autostart
-------------------------------
 default   active   yes
 iso       active   yes
```

## Create a volume in a storage pool and start the install

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

# Removing and deleting a VM
```
$ virsh shutdown ubuntu-image
# "Force off" the VM - doesn't actually remove the VM
$ virsh destroy ubuntu-image
# Optionally add --remove-all-storage to remove the storage pool
$ virsh undefine ubuntu-image --nvram
$ virsh vol-delete --pool default ubuntu-image.qcow2
Vol ubuntu-image.qcow2 deleted
```

```
virt-install \
  --connect qemu:///system \
  --name testy-ubuntu \
  --vcpus 2 \
  --memory 2048 \
  --boot uefi \
  --cdrom /var/lib/libvirt/isos/ubuntu-22.04.3-live-server-amd64.iso \
  --network network=host-network,model=virtio \
  --disk bus=virtio,size=32 \
  --os-variant ubuntu22.04

## BIOS PXE boot
virt-install \
  --connect qemu:///system \
  --name testy-ubuntu \
  --vcpus 2 \
  --memory 2048 \
  --pxe \
  --network network=host-network,model=virtio \
  --disk path=/var/lib/libvirt/images/testy-ubuntu.qcow2,bus=virtio,size=32 \
  --os-variant ubuntu22.04

## UEFI PXE boot
sudo dd if=/dev/zero of=/var/lib/libvirt/images/testy-ubuntu-efivars.fd bs=1M count=64
sudo dd if=/usr/share/AAVMF/AAVMF_VARS.fd of=/var/lib/libvirt/images/testy-ubuntu-efivars.fd conv=notrunc

virt-install \
  --connect qemu:///system \
  --name ubuntu-image \
  --vcpus 2 \
  --memory 2048 \
  --boot uefi \
  --network network=host-network,model=virtio \
  --disk path=/var/lib/libvirt/images/ubuntu-image.qcow2,bus=virtio,size=32 \
  --os-variant ubuntu22.04 \
  --print-xml > vm.xml

virsh define vm.xml


virt-install \
  --connect qemu:///system \
  --name ubuntu-image \
  --boot uefi \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu20.04 \
  --disk path=/data/vms/ubuntu-image.qcow2,bus=virtio \
  --import \
  --noautoconsole \
  --network network=default,model=virtio \
  --graphics spice \
  --video model=virtio \
  --console pty,target_type=serial
```

### Installing Ubuntu 24.04 Server on a headless Ubuntu Server using VNC

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server \
  --boot uefi \
  --cdrom /var/lib/libvirt/iso/ubuntu-24.04-live-server-amd64.iso \
  --memory 16384 \
  --vcpus 4 \
  --os-variant ubuntu20.04 \
  --disk pool=default,size=50,bus=virtio,format=qcow2 \
  --network bridge=br0,model=virtio \
  --graphics vnc,listen=0.0.0.0,password=foobar \
  --noautoconsole \
  --console pty,target_type=serial \
  --debug

$ virsh vncdisplay ubuntu-server
:0
$ virsh dumpxml ubuntu-server | grep "graphics type='vnc'"
    <graphics type='vnc' port='5900' autoport='yes' listen='0.0.0.0'>

# enable serial service in VM
sudo systemctl enable --now serial-getty@ttyS0.service


virsh destroy ubuntu-server
virsh undefine ubuntu-server --nvram --remove-all-storage
```

### Installing Ubuntu 24.04 Desktop on a headless Ubuntu Server using VN

```
virsh vol-create-as default ubuntu-desktop-2404.qcow2 64G --format qcow2

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

# Snapshots
virsh snapshot-create ubuntu-desktop-2404 
virsh snapshot-list ubuntu-desktop-2404
virsh snapshot-revert ubuntu-desktop-2404 <name>
virsh snapshot-delete ubuntu-desktop-2404 <name>

virsh destroy ubuntu-desktop-2404
virsh undefine ubuntu-desktop-2404 --nvram --remove-all-storage
```
