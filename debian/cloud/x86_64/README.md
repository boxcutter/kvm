# Debian x86_64 cloud images

## Debian 12 UEFI

```
cd debian/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file debian-12-x86_64.pkrvars.hcl \
  debian.pkr.hcl
```

```

$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-debian-12-x86_64/debian-12-x86_64.qcow2 \
    /var/lib/libvirt/images/debian-12-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/debian-12-x86_64.qcow2 \
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
  --disk /var/lib/libvirt/images/debian-12-x86_64.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console debian-12

# login with packer user

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not 
# correct, can regenerate with cloud-init
# ip reports that enp1s0 is down
$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           DOWN

# Make cloud-init regenerate the network configuration
sudo cloud-init clean --logs
sudo cloud-init init --local

$ sudo reboot

# Verify image boots with the networking enabled
$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           UP             10.63.46.11/22 metric 100 fe80::5054:ff:fe04:483/64

# Verify cloud-init is disabled
$ cloud-init status
status: disabled
```

```
$ virsh shutdown debian-12
$ virsh undefine debian-12 --nvram --remove-all-storage
```

## Debian 12 BIOS

```
cd debian/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file debian-12-bios-x86_64.pkrvars.hcl \
  debian.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-debian-12-bios-x86_64/debian-12-bios-x86_64.qcow2 \
    /var/lib/libvirt/images/debian-12.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/debian-12.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name debian-12 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant debian12 \
  --disk /var/lib/libvirt/images/debian-12.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console debian-12

# login with packer user

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not
# correct, can regenerate with cloud-init
# ip reports that enp1s0 is down
$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           DOWN

# NOTE: Because Ubuntu 20.04 has a version of cloud-init earlier than 23.4
# it does not have the "clean" parameter, instead regenerate the netplan
# config with the following

# Make cloud-init regenerate the network configuration
sudo cloud-init clean --logs
sudo cloud-init init --local

$ sudo reboot

# Verify cloud-init is disabled
$ cloud-init status
status: disabled
```

```
$ virsh shutdown debian-12
$ virsh undefine debian-12 --nvram --remove-all-storage
```
