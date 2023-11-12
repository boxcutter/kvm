# Installing an OS from an ISO without automation

## Create a storage pool for ISOs
Create a storage pool for your ISOs, so that virsh has permission to access them.
By default a clean KVM install does not define any storage pools.

```
# Create the storage pool definition
$ virsh pool-define-as --name iso --type dir --target /var/lib/libvirt/iso
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

$ virsh vol-list --pool iso --details
 Name   Path   Type   Capacity   Allocation
---------------------------------------------

# Start the storage pool
$ virsh pool-start iso
Pool iso started

$ virsh pool-list --all
 Name           State    Autostart
------------------------------------
 boot-scratch   active   yes
 default        active   yes
 iso            active   no

# Turn on autostart
$ virsh pool-autostart iso
Pool iso marked as autostarted

$ virsh pool-list --all
 Name           State    Autostart
------------------------------------
 boot-scratch   active   yes
 default        active   yes
 iso            active   yes

# Verify the storage pool configuration
$ virsh pool-info iso
Name:           iso
UUID:           a5110ddc-1142-4a49-9652-0232280cf5a7
State:          running
Persistent:     yes
Autostart:      yes
Capacity:       960.65 GiB
Allocation:     131.41 GiB
Available:      829.24 GiB

$ sudo ls -ld /var/lib/libvirt/iso
drwx--x--x 2 root root 4096 Oct  7 14:47 /var/lib/libvirt/iso

$ sudo curl -L https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso -o /var/lib/libvirt/iso/ubuntu-22.04.3-live-server-amd64.iso

$ sudo shasum -a 256 /var/lib/libvirt/iso/ubuntu-22.04.3-live-server-amd64.iso
a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd  /var/lib/libvirt/iso/ubuntu-22.04.3-live-server-amd64.iso
```

```
$ virsh vol-create-as default ubuntu-image.qcow2 20G --format qcow2
Vol ubuntu-image.qcow2 created

$ virsh vol-info --pool default ubuntu-image.qcow2
Name:           ubuntu-image.qcow2
Type:           file
Capacity:       20.00 GiB
Allocation:     196.00 KiB

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

$ virsh domblklist ubuntu-image
 Target   Source
--------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-image-1.qcow2
```

```
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
