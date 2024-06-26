# kvm

Packer templates for producing KVM/QEMU images written in HCL.

This repo contains source code that can be used to create a
pipeline that customizes the qcow2 base images from all of the major Linux
distros. You can use these examples to create your own customized
minimalizst Linux images with "Just Enough Operating System" to
bootstrap an appliance with further automation specific to your use case.

Examples are provided that create virtual machines images for both
x86_64 and ARM64 processors with hardware acceleration. For x86_64 processors,
examples are provided images with either the Legacy BIOS firmware or the
Unified Extensible Firmware Interface (UEFI). Since ARM64 processors don't
support Legacy BIOS firmware, only UEFI examples are provided for ARM64.

The SeaBIOS open source implementation of a 16-bit X86 BIOS is used for the
Legacy BIOS firmware in these images. And the TianoCore open source implentation
is used for images with UEFI firmware.

> NOTE: We don't bother creating vagrant boxes compatible with the
> vagrant-libvirt plugin. There's no ARM64 version of vagrant for Linux.
> The vagrant-libvirt hasn't been updated in almost a year as of this writing.
> Troubleshooting all the ruby dependencies for the vagrant-libvirt plugin is
> so complicated it's easier to run vagrant in a Docker container. And then
> there are still so many issues troubleshooting the xml output of
> vagrant-libvirt, it's just easier to avoid using vagrant entirely. By
> comparison, using libvirt or qemu to work with the qcow2 images directly
> is easier than trying to use these as vagrant boxes for our use case in
> robotics.

> run vagrant in 


## Building the images

Prequisites:

- Install [Hashicorp Packer](docs/INSTALL_PACKER.md)
- Install [QEMU/KVM](docs/INSTALL_QEMU_KVM.md)

In the root of this repo there are directories with examples for the following
distros:

- `centos`
- `debian`
- `oraclinux`
- `ubuntu`

Each distro directory has a subdirectory for each processor architecture. You'll
want to make each directory the current directory when run Hashcirop packer
to create images for each processor. There's also a `scripts` directory that
contains shared code referenced by each processor build.

- `aarch64` - ARM64 processor architecture
- `x86_64` - X86_64/AMD64/Intel 64 processor architecture

### Building x86_64 images

```
cd ubuntu/iso/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file ubuntu-24.04-x86_64.pkrvars.hcl \
  ubuntu.pkr.hcl

PACKER_LOG=1 packer build \
  -var-file ubuntu-24.04-bios-x86_64.pkrvars.hcl \
  ubuntu.pkr.hcl
```

### Building aarch64 images
```
cd ubuntu/aarch64
PACKER_LOG=1 packer build \
  -var-file ubuntu-22.04-aarch64.pkrvars.hcl \
  ubuntu.pkr.hcl
```

## Using the images

Ironically on Linux, it's easiest to use Docker or Podman to load the required
dependencies for the Vagrant Libvirt plugin for Vagrant. For more information
refer to the [Vagrant Libvirt Documentation](https://vagrant-libvirt.github.io/vagrant-libvirt/installation#requirements).

```
# Create $HOME/.vagrant.d if it doesn't exist
mkdir -p $HOME/.vagrant.d

docker run --interactive --tty --rm \
  --env LIBVIRT_DEFAULT_URI \
  --mount type=bind,source=/var/run/libvirt/,target=/var/run/libvirt/ \
  --mount type=bind,source=$HOME/.vagrant.d,target=/.vagrant.d \
  --mount type=bind,source=$(realpath "${PWD}"),target=${PWD} \
  --workdir "${PWD}" \
  --network host \
  vagrantlibvirt/vagrant-libvirt:latest \
    vagrant status

```

# Give permission to allow user VMs to access bridged device

```
mkdir -p /etc/qemu
cat >/etc/qemu/bridge.conf <<EOF
allow br0
EOF
chown root:root /etc/qemu/bridge.conf
chmod 0644 /etc/qemu/bridge.conf
# Add setuid to the qemu-bridge-helper binary
chmod u+s /usr/lib/qemu/qemu-bridge-helper
```

# https://wiki.qemu.org/Documentation/Networking

```
$ qemu-img convert -O qcow2 output-ubuntu-22.04-bios-x86_64/ubuntu-22.04-bios-x86_64 ubuntu-image.qcow2
$ qemu-img resize -f qcow2 ubuntu-image.qcow2 32G
$ qemu-system-x86_64 \
  -name ubuntu-image \
  -machine accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -net bridge,br=br0 -net nic,macaddr=${mac},model=virtio
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=ubuntu-image.qcow2,if=virtio,format=qcow2
```


### QEMU x86_64 BIOS

```
$ qemu-img convert -O qcow2 output-ubuntu-22.04-bios-x86_64/ubuntu-22.04-bios-x86_64 ubuntu-image.qcow2
$ qemu-img resize -f qcow2 ubuntu-image.qcow2 32G
$ qemu-system-x86_64 \
  -name ubuntu-image \
  -machine accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=ubuntu-image.qcow2,if=virtio,format=qcow2
```

### QEMU x86_64 UEFI

```
$ qemu-img convert -O qcow2 output-ubuntu-22.04-x86_64/ubuntu-22.04-x86_64 ubuntu-image.qcow2
$ cp output-ubuntu-22.04-x86_64/efivars.fd ubuntu-image-efivars.fd
$ qemu-img resize -f qcow2 ubuntu-image.qcow2 32G
$ qemu-system-x86_64 \
  -name ubuntu-image \
  -machine accel=kvm,type=q35 \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=ubuntu-image.qcow2,if=virtio,format=qcow2 \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=pflash,format=raw,unit=1,file=ubuntu-image-efivars.fd
```

### QEMU aarch64 UEFI

```
$ qemu-img convert -O qcow2 output-ubuntu-22.04-aarch64/ubuntu-22.04-aarch64 ubuntu-image.qcow2
$ cp output-ubuntu-22.04-aarch64/efivars.fd ubuntu-image-efivars.fd
$ qemu-img resize -f qcow2 ubuntu-image.qcow2 32G
qemu-system-aarch64 \
  -name ubuntu-image \
  -machine accel=kvm,type=virt \
  -cpu host \
  -smp 2 \
  -m 2G \
  -device virtio-keyboard \
  -device virtio-mouse \
  -device virtio-gpu-pci \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive file=ubuntu-image.qcow2,if=virtio,format=qcow2 \
  -drive if=pflash,format=raw,readonly=on,unit=0,file=/usr/share/AAVMF/AAVMF_CODE.fd \
  -drive if=pflash,format=raw,unit=1,file=ubuntu-image-efivars.fd
```

### libvirt x86_64 BIOS

```
sudo qemu-img convert -O qcow2 output-ubuntu-22.04-bios-x86_64/ubuntu-22.04-bios-x86_64 /var/lib/libvirt/images/ubuntu-image.qcow2
sudo qemu-img resize -f qcow2 /var/lib/libvirt/images/ubuntu-image.qcow2 32G

virt-install \
  --name ubuntu-image \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk path=/var/lib/libvirt/images/ubuntu-image.qcow2,bus=virtio \
  --import \
  --noautoconsole \
  --network network=default,model=virtio \
  --graphics spice \
  --video model=virtio \
  --console pty,target_type=serial

virt-install \
  --connect qemu:///system \
  --name ubuntu-image \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk path=/var/lib/libvirt/images/ubuntu-image.qcow2,bus=virtio \
  --import \
  --noautoconsole \
  --network network=default,model=virtio \
  --graphics spice \
  --video model=virtio \
  --console pty,target_type=serial

virsh console ubuntu-image
virt-viewer ubuntu-image

virsh destroy ubuntu-image
virsh undefine ubuntu-image --remove-all-storage
```

### libvirt x86_64 UEFI

```
# You can get paths of the pools from /etc/libvirt/storage
sudo qemu-img convert -O qcow2 output-ubuntu-22.04-x86_64/ubuntu-22.04-x86_64 /var/lib/libvirt/images/ubuntu-image.qcow2
sudo qemu-img resize -f qcow2 /var/lib/libvirt/images/ubuntu-image.qcow2 32G

virt-install \
  --connect qemu:///system \
  --name ubuntu-image \
  --boot uefi \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu22.04 \
  --disk path=/var/lib/libvirt/images/ubuntu-image.qcow2,bus=virtio \
  --import \
  --noautoconsole \
  --network network=default,model=virtio \
  --graphics spice \
  --video model=virtio \
  --console pty,target_type=serial

sudo rm 50-cloud-init.yaml
sudo vi /etc/netplan/00-installer-config.yaml
network:
  ethernets:
    enp1s0:
      dhcp4: true
  version: 2

sudo vi /etc/hosts
127.0.0.1 localhost ubuntu-cloud

sudo netplan apply
virsh console ubuntu-image
virt-viewer ubuntu-image

virsh destroy ubuntu-image
virsh undefine ubuntu-image --nvram --remove-all-storage
```

### libvirt aarch64 UEFI

```
# You can get paths of the pools from /etc/libvirt/storage
# /data/vms
# /var/lib/libvirt/images

qemu-img convert -O qcow2 output-ubuntu-22.04-aarch64/ubuntu-22.04-aarch64 /data/vms/ubuntu-image.qcow2
qemu-img resize -f qcow2 /data/vms/ubuntu-image.qcow2 32G

virt-install \
  --connect qemu:///system \
  --name ubuntu-image \
  --boot uefi \
  --memory 2048 \
  --vcpus 2 \
  --os-variant ubuntu20.04 \
  --disk path=/data/vms/ubuntu-image.qcow2,bus=virtio \
  --import \
  --noautoconsole \
  --network network=default,model=virtio \
  --graphics spice \
  --video model=virtio \
  --console pty,target_type=serial

virsh console ubuntu-image
virt-viewer ubuntu-image

virsh destroy ubuntu-image
virsh undefine ubuntu-image --nvram --remove-all-storage
```

#
#
#

https://www.dzombak.com/blog/2024/02/Setting-up-KVM-virtual-machines-using-a-bridged-network.html

virsh net-list
virsh net-info hostbridge
virsh net-dhcp-leases hostbridge
sudo brctl show br0
