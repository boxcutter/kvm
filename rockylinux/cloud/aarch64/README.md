# Rocky Linux Cloud Images

## Rock Linux 9

```
cd rockylinux/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file rockylinux-9-aarch64.pkrvars.hcl \
  rockylinux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-rockylinux-9-aarch64/rockylinux-9-aarch64.qcow2 \
    /var/lib/libvirt/images/rockylinux-9-aarch64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/rockylinux-9-aarch64.qcow2 \
    32G
```

```
osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name rockylinux-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ol8.0 \
  --disk /var/lib/libvirt/images/rockylinux-9-aarch64.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console rockylinux-9

# login with packer user


# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not
# correct, can regenerate with cloud-init

$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.63.33.48/22 fe80::5054:ff:fed5:f99/64

# Check cloud-init version
$ cloud-init --version
/usr/bin/cl
oud-init 23
.4-7.el9_4.
0.1

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

$ sudo reboot

$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             10.63.34.53/22 fe80::5054:ff:fed1:cf06/64

$ sudo cloud-init status
status: done

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ sudo cloud-init status
status: disabled

$ sudo shutdown -h now
```

```
$ virsh shutdown rockylinux-9
$ virsh undefine rockylinux-9 --nvram --remove-all-storage
```

