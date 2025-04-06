# CentOS Cloud Images

## CentOS Stream 10 UEFI virtual firmware

```
cd centos/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-10-x86_64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-10-x86_64/centos-stream-10-x86_64.qcow2 \
    /var/lib/libvirt/images/centos-stream-10.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/centos-stream-10.qcow2 \
    32G
```

```
osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name centos-stream-10 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos-stream9 \
  --disk /var/lib/libvirt/images/centos-stream-10.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console centos-stream-10

# login with packer user

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not
# correct, can regenerate with cloud-init
# ip reports that enp1s0 is down
$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.63.44.89/22 fe80::ea9d:34f2:68cc:bc78/64

# Check cloud-init version
$ cloud-init --version
/usr/bin/cl
oud-init
23.4-11.el9

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

$ sudo reboot

$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.63.44.89/22 fe80::5054:ff:fe12:a922/64

# Verify cloud-init is disabled
$ sudo cloud-init status
status: disabled
```

```
$ virsh shutdown centos-stream-10
$ virsh undefine centos-stream-10 --nvram --remove-all-storage
```

## CentOS Stream 9 UEFI virtual firmware

```
cd centos/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-9-x86_64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-9-x86_64/centos-stream-9-x86_64.qcow2 \
    /var/lib/libvirt/images/centos-stream-9.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/centos-stream-9.qcow2 \
    32G
```

```
osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name centos-stream-9 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos-stream9 \
  --disk /var/lib/libvirt/images/centos-stream-9.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console centos-stream-9

# login with packer user

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not
# correct, can regenerate with cloud-init
# ip reports that enp1s0 is down
$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.63.44.89/22 fe80::ea9d:34f2:68cc:bc78/64

# Check cloud-init version
$ cloud-init --version
/usr/bin/cl
oud-init
23.4-11.el9

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

$ sudo reboot

$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.63.44.89/22 fe80::5054:ff:fe12:a922/64

# Verify cloud-init is disabled
$ sudo cloud-init status
status: disabled
```

```
$ virsh shutdown centos-stream-9
$ virsh undefine centos-stream-9 --nvram --remove-all-storage
```
