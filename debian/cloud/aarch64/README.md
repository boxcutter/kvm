# Debian aarch64 cloud images

## Debian 12

```
cd debian/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file debian-12-aarch64.pkrvars.hcl \
  debian.pkr.hcl
```

```

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-debian-12-aarch64/debian-12-aarch64.qcow2 \
    /var/lib/libvirt/images/debian-12-aarch64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/debian-12-aarch64.qcow2 \
    32G
```

```
$ sudo apt-get install libosinfo-bin
$ osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name debian-12 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant debian12 \
  --disk /var/lib/libvirt/images/debian-12-aarch64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console debian-12

# login with packer user

# Make sure cloud-init is finished
$ cloud-init status --wait
status: done

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not 
# correct, can regenerate with cloud-init

# Check to make sure cloud-init is greater than 23.4
$ cloud-init --version

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ cloud-init status
status: disabled

$ sudo reboot

# Verify image boots with the networking enabled
$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           UP             10.63.46.11/22 metric 100 fe80::5054:ff:fe04:483/64
```

```
$ virsh shutdown debian-12
$ virsh undefine debian-12 --nvram --remove-all-storage
```
