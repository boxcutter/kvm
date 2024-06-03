# Libvirt cloud images on Nvidia Jetson

# Create a storage pool for cloud-init boot images

> **Note:**
> There is a `--cloud-init` parameter for `virt-install` to auto-generate the
> cloud-init ISO. It creates a pool called `boot-scratch` in
> `/var/lib/libvirt/boot`. However oftentimes it's just easier to control the
> lifecycle of these images manually

```
# Create the storage pool definition
$ virsh pool-define-as \
    --name boot-scratch \
    --type dir \
    --target /var/lib/libvirt/boot
Pool iso defined

# Create the local directory
$ virsh pool-build boot-scratch
# Start the storage pool
$ virsh pool-start boot-scratch
# Turn on autostart
$ virsh pool-autostart boot-scratch

# Verify the storage pool is listed
$ virsh pool-list --all
 Name           State    Autostart
------------------------------------
 boot-scratch   active   yes
 default        active   yes
 iso            active   yes

$ virsh vol-list --pool boot-scratch --details
 Name   Path   Type   Capacity   Allocation
---------------------------------------------

# Verify the storage pool configuration
$ virsh pool-info boot-scratch
Name:           boot-scratch
UUID:           9e3bfda7-299e-4b40-8ce5-82a08f150368
State:          running
Persistent:     yes
Autostart:      yes
Capacity:       6.93 TiB
Allocation:     121.86 GiB
Available:      6.81 TiB
```

## Download the Ubuntu Cloud Image
```
# JetPack 5.x
mkdir ~/ubuntu-server-2004 && cd ~/ubuntu-server-2004
curl -LO https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-arm64.img

# JetPack 6.x
mkdir ~/ubuntu-server-2204 && cd ~/ubuntu-server-2204
curl -LO https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.img

$ qemu-img info jammy-server-cloudimg-arm64.img 
image: jammy-server-cloudimg-arm64.img
file format: qcow2
virtual size: 2.2 GiB (2361393152 bytes)
disk size: 594 MiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    refcount bits: 16

sudo qemu-img convert -f qcow2 -O qcow2 jammy-server-cloudimg-arm64.img /var/lib/libvirt/images/ubuntu-server-2204.qcow2
sudo qemu-img resize -f qcow2 /var/lib/libvirt/images/ubuntu-server-2204.qcow2 32G
```

```
touch network-config

cat >meta-data <<EOF
instance-id: ubuntu-server-2204
local-hostname: ubuntu-server-2204
EOF

# openssl passwd -6 <password>
cat >user-data <<EOF
#cloud-config
hostname: ubuntu-server-2204.corp.polymathrobotics.dev
users:
  - default
  - name: automat
    groups: users
    shell: /bin/bash
    passwd: $6$WmRgh/NiWY/OIot.$SY0X.EfPAVxzfAizOaua5j10HfacJbJEFnCh0M9T81nqm1i05.BaRx.p9KUqiJEptbS891kPpA7V3vbt6NaFS0
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh_authorized_keys:
      - <ssh pub key 1>
packages:
  - qemu-guest-agent
growpart:
  mode: auto
  devices: ['/']
power_state:
  mode: reboot
EOF
```

```
sudo apt-get update
sudo apt-get install genisoimage
genisoimage \
    -input-charset utf-8 \
    -output ubuntu-server-2204-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp ubuntu-server-2204-cloud-init.img /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso
```

```
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2204 \
  --boot uefi \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu20.04 \
  --disk /var/lib/libvirt/images/ubuntu-server-2204.qcow2 \
  --disk /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import \
  --debug

virsh console ubuntu-server-2204

# Disable cloud-init
$ sudo touch /etc/cloud/cloud-init.disabled

$ cloud-init status
status: disabled

$ sudo shutdown -h now

$ virsh domblklist ubuntu-server-2204
 Target   Source
----------------------------------------------------------------------
 vda      /var/lib/libvirt/images/ubuntu-server-2204/root-disk.qcow2
 sda      /var/lib/libvirt/images/ubuntu-server-2204/seed.iso

$ virsh change-media ubuntu-server-2204 sda --eject
Successfully ejected media.

$ sudo rm /var/lib/libvirt/boot/ubuntu-server-2204-cloud-init.iso
$ virsh edit ubuntu-server-2204
# remove entry for the seed.iso
<disk type='file' device='cdrom'>
    <driver name='qemu' type='raw'/>
    <source file='/var/lib/libvirt/images/ubuntu-server-2204/seed.iso'/>
    <target dev='sda' bus='scsi'/>
    <readonly/>
    <address type='drive' controller='0' bus='0' target='0' unit='0'/>
</disk>
```

## References

Cloud Images with cloud-init Demystified https://packetpushers.net/blog/cloud-init-demystified/

Add nodes to your private cloud using Cloud-init https://opensource.com/article/20/5/create-simple-cloud-init-service-your-homelab
