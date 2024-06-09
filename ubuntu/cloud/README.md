# Ubuntu cloud images

## Ubuntu 20.04 UEFI virtual firmware

```
cd ubuntu/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file ubuntu-20.04-x86_64.pkrvars.hcl \
  ubuntu.pkr.hcl
```

```
$ sudo cp boot-ubuntu-20.04-x86_64/cidata.iso \
  /var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-ubuntu-20.04-x86_64/ubuntu-20.04-x86_64.qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2004.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2004.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2004 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2004.qcow2,bus=virtio \
  --disk /var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2004

# login with ubuntu user
$ cloud-init status --wait
status: done

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ cloud-init status
status: disabled

$ sudo shutdown -h now

$ virsh domblklist ubuntu-server-2004
 Target   Source
-------------------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-server-2004.qcow2
 sda      /var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso

$ virsh change-media ubuntu-server-2004 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso
$ virsh edit ubuntu-server-2004
# remove entry for the cloud-init.iso
<!--
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='/var/lib/libvirt/boot/ubuntu-server-2004-cloud-init.iso'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
-->

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown ubuntu-server-2004
$ virsh undefine ubuntu-server-2004 --nvram --remove-all-storage
```
