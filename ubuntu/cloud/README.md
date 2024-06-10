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
  --os-variant ubuntu20.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2004.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2004

# login with packer user

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not 
# correct, can regenerate with cloud-init
# ip reports that enp1s0 is down
$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           DOWN

# Netplan was configured with a different interface name - ens3
$ netplan get
network:
  version: 2
  ethernets:
    ens3:
      match:
        macaddress: "52:54:00:12:34:56"
      dhcp4: true
      dhcp6: true
      set-name: "ens3"

# NOTE: Because Ubuntu 20.04 has a version of cloud-init earlier than 23.4
# it does not have the "clean" parameter, instead regenerate the netplan
# Check networking - if not correct, can regenerate with cloud-init
# NOTE: Because Ubuntu 20.04 has a version of cloud-init earlier than 23.4
# it does not have the "clean" parameter, instead regenerate the netplan
# config with the following

# Make cloud-init regenerate the network configuration
sudo rm /var/lib/cloud/data/instance-id
sudo cloud-init init --local

# Apply the new netplan config
sudo netplan apply


# Verify cloud-init is disabled
$ cloud-init status
status: disabled

$ sudo shutdown -h now

# Verify image boots with the networking enabled
$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           UP             192.168.107.79/24 fda2:8d37:bed8:93ee:5054:ff:fe8c:e161/64 fe80::5054:ff:fe8c:e161/64
```

```
$ virsh shutdown ubuntu-server-2004
$ virsh undefine ubuntu-server-2004 --nvram --remove-all-storage
```

## Ubuntu 20.04 BIOS virtual firmware

```
cd ubuntu/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file ubuntu-20.04-bios-x86_64.pkrvars.hcl \
  ubuntu.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-ubuntu-20.04-bios-x86_64/ubuntu-20.04-bios-x86_64.qcow2 \
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
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu20.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2004.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2004

# login with packer user

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not 
# correct, can regenerate with cloud-init
# ip reports that enp1s0 is down
$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           DOWN

# Netplan was configured with a different interface name - ens3
$ netplan get
network:
  version: 2
  ethernets:
    ens3:
      match:
        macaddress: "52:54:00:12:34:56"
      dhcp4: true
      dhcp6: true
      set-name: "ens3"

# NOTE: Because Ubuntu 20.04 has a version of cloud-init earlier than 23.4
# it does not have the "clean" parameter, instead regenerate the netplan
# config with the following

# Make cloud-init regenerate the network configuration
sudo rm /var/lib/cloud/data/instance-id
sudo cloud-init init --local

# Apply the new netplan config
sudo netplan apply


# Verify cloud-init is disabled
$ cloud-init status
status: disabled

$ sudo shutdown -h now

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown ubuntu-server-2004
$ virsh undefine ubuntu-server-2004 --nvram --remove-all-storage
```

## Ubuntu 22.04 UEFI virtual firmware

```
cd ubuntu/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file ubuntu-22.04-x86_64.pkrvars.hcl \
  ubuntu.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-ubuntu-22.04-x86_64/ubuntu-22.04-x86_64.qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2204.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2204.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2204 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2204.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2204

# login with packer user

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not 
# correct, can regenerate with cloud-init
# ip reports that enp1s0 is down
$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           DOWN

# Netplan was configured with a different interface name - ens3
$ sudo netplan get
network:
  version: 2
  ethernets:
    ens3:
      match:
        macaddress: "52:54:00:12:34:56"
      dhcp4: true
      dhcp6: true
      set-name: "ens3"

# Check to make sure cloud-init is greater than 23.4
$ cloud-init --version
/usr/bin/cloud-init 24.1.3-0ubuntu1~22.04.1

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

# Now netplan should be configured to use the correct interface

# Verify cloud-init is disabled
$ cloud-init status
status: disabled

$ sudo shutdown -h now

# Verify image boots with the networking enabled
$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           UP             192.168.107.79/24 fda2:8d37:bed8:93ee:5054:ff:fe8c:e161/64 fe80::5054:ff:fe8c:e161/64
```

```
$ virsh shutdown ubuntu-server-2004
$ virsh undefine ubuntu-server-2004 --nvram --remove-all-storage
```

## Ubuntu 22.04 BIOS virtual firmware

```
cd ubuntu/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file ubuntu-22.04-bios-x86_64.pkrvars.hcl \
  ubuntu.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-ubuntu-22.04-bios-x86_64/ubuntu-22.04-bios-x86_64.qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2204.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/ubuntu-server-2204.qcow2 \
    32G
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2204 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2204.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2204

# login with packer user

# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not 
# correct, can regenerate with cloud-init
# ip reports that enp1s0 is down
$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           DOWN

# Netplan was configured with a different interface name - ens3
$ sudo netplan get
network:
  version: 2
  ethernets:
    ens3:
      match:
        macaddress: "52:54:00:12:34:56"
      dhcp4: true
      dhcp6: true
      set-name: "ens3"

# Check to make sure cloud-init is greater than 23.4
$ cloud-init --version
/usr/bin/cloud-init 24.1.3-0ubuntu1~22.04.1

# Regenerate only the network config
$ sudo cloud-init clean --configs network
$ sudo cloud-init init --local

# Now netplan should be configured to use the correct interface

# Verify cloud-init is disabled
$ cloud-init status
status: disabled

$ sudo shutdown -h now

# Verify image boots without cloud-init iso being mounted
```

```
$ virsh shutdown ubuntu-server-2204
$ virsh undefine ubuntu-server-2204 --nvram --remove-all-storage
```


## References:

https://askubuntu.com/questions/1104285/how-do-i-reload-network-configuration-with-cloud-init


References:

https://askubuntu.com/questions/1104285/how-do-i-reload-network-configuration-with-cloud-init
