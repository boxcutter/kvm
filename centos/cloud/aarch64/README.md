# CentOS Cloud Images

## CentOS Stream 10 UEFI virtual firmware

```
cd centos/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-10-aarch64.pkrvars.hcl \
  centos.pkr.hcl
```

```
$ sudo qemu-img convert \
    -f qcow2 \
    -O qcow2 \
    output-centos-stream-10-aarch64/centos-stream-10-aarch64.qcow2 \
    /var/lib/libvirt/images/centos-stream-10.qcow2
$ sudo qemu-img resize \
    -f qcow2 \
    /var/lib/libvirt/images/centos-stream-10.qcow2 \
    32G
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
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console centos-stream-10

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

$ sudo shutdown -h now

# Verify image boots with the networking enabled
$ ip --brief a
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           UP             192.168.107.79/24 fda2:8d37:bed8:93ee:5054:ff:fe8c:e161/64 fe80::5054:ff:fe8c:e161/64
```

```
$ virsh shutdown ubuntu-server-2204
$ virsh undefine ubuntu-server-2204 --nvram --remove-all-storage
```

## CentOS Stream 9 UEFI virtual firmware

```
cd centos/cloud/aarch64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-9-aarch64.pkrvars.hcl \
  centos.pkr.hcl
```
