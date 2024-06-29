# Amazon Linux Cloud Images

https://docs.aws.amazon.com/linux/al2023/ug/kvm-supported-configurations.html

https://cdn.amazonlinux.com/os-images/latest/kvm/

https://cdn.amazonlinux.com/os-images/2.0.20240610.1/README.cloud-init

## Amazon Linux 2

```
cd amazonlinux/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file amazonlinux-2-bios-x86_64.pkrvars.hcl \
  amazonlinux.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-amazonlinux-2-bios-x86_64/amazonlinux-2-x86_64.qcow2 \
    /var/lib/libvirt/images/amazonlinux-2-bios-x86_64.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/amazonlinux-2-bios-x86_64.qcow2 \
    32G
```

```
osinfo-query os
```

```
virt-install \
  --connect qemu:///system \
  --name amazonlinux-2 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant centos8 \
  --disk /var/lib/libvirt/images/amazonlinux-2-bios-x86_64.qcow2,bus=virtio \
  --network network=host-network,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console amazonlinux-2

# login with packer user


# Check networking - you may notice that the network interface is down and
# the name of the interface generated in netplan doesn't match. If not
# correct, can regenerate with cloud-init

$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             10.63.33.48/22 fe80::5054:ff:fed5:f99/64

# Check cloud-init version
$ cloud-init --version
/usr/bin/cloud-init 19.3-46.amzn2.0.2

# NOTE: Because Amazon Linux has a version of cloud-init earlier than 23.4
# it does not have the "clean" parameter, instead regenerate the netplan
# Check networking - if not correct, can regenerate with cloud-init
# NOTE: Because Amazon Linux  has a version of cloud-init earlier than 23.4
# it does not have the "clean" parameter, instead regenerate the netplan
# config with the following

# Make cloud-init regenerate the network configuration
sudo rm /var/lib/cloud/data/instance-id
sudo cloud-init init --local

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
$ virsh shutdown amazonlinux-2
$ virsh undefine amazonlinux-2 --nvram --remove-all-storage
```
