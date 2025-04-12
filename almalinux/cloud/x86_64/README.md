# AlmaLinux OS Generic Cloud (Cloud-init) images

https://wiki.almalinux.org/cloud/Generic-cloud.html#download-images

https://github.com/AlmaLinux/cloud-images

## AlmaLinux 9

```
cd almalinux/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file almalinux-9-x86_64.pkrvars.hcl \
  almalinux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-almalinux-9-x86_64/almalinux-9-x86_64.qcow2 \
    /var/lib/libvirt/images/almalinux-9-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/almalinux-9-x86_64.qcow2 \
    32G
```

```
osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name almalinux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant almalinux9 \
  --disk /var/lib/libvirt/images/almalinux-9-x86_64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --console pty,target_type=serial \
  --import \
  --noautoconsole \
  --debug


virsh console almalinux-9

# login with packer user

# Make sure cloud-init is finished
$ sudo cloud-init status --wait
status: done

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not
# correct, can regenerate with cloud-init
$ ip --brief a

# Check cloud-init version
$ cloud-init --version

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

$ sudo reboot

$ sudo cloud-init status
status: done

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ sudo cloud-init status
status: disabled

$ sudo shutdown -h now
```

```
$ virsh shutdown almalinux-9
$ virsh undefine almalinux-9 --nvram --remove-all-storage
```
