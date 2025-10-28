# Manual install NixOS ISO

## Minimal ISO image

```
mkdir nixos-bios
cd nixos-bios

curl -LO https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-x86_64-linux.iso
curl -LO https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-x86_64-linux.iso.sha256

sudo cp latest-nixos-minimal-x86_64-linux.iso \
  /var/lib/libvirt/iso/latest-nixos-minimal-x86_64-linux.iso

virt-install \
  --connect qemu:///system \
  --name nixos-bios \
  --cdrom /var/lib/libvirt/iso/latest-nixos-minimal-x86_64-linux.iso \
  --disk pool=default,format=qcow2,bus=virtio,size=60 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant nixos-25.05 \
  --network network=host-network,model=virtio \
  --graphics none \
  --console pty,target_type=serial

# Hit ESC
boot-serial

virsh destroy nixos-bios
virsh undefine nixos-bios --remove-all-storage
```

## Graphical ISO image - BIOS

```
mkdir nixos
cd nixos

curl -LO https://channels.nixos.org/nixos-25.05/latest-nixos-graphical-x86_64-linux.iso
curl -LO https://channels.nixos.org/nixos-25.05/latest-nixos-graphical-x86_64-linux.iso.sha256

sudo cp latest-nixos-graphical-x86_64-linux.iso \
  /var/lib/libvirt/iso/latest-nixos-graphical-x86_64-linux.iso


virt-install \
  --connect qemu:///system \
  --name nixos \
  --cdrom /var/lib/libvirt/iso/latest-nixos-graphical-x86_64-linux.iso \
  --disk pool=default,format=qcow2,bus=virtio,size=60 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant nixos-25.05 \
  --network network=host-network,model=virtio \
  --graphics spice \
  --video virtio \
  --sound ich9 \
  --rng /dev/urandom
```

## Graphical ISO image - UEFI

```
mkdir nixos
cd nixos

curl -LO https://channels.nixos.org/nixos-25.05/latest-nixos-graphical-x86_64-linux.iso
curl -LO https://channels.nixos.org/nixos-25.05/latest-nixos-graphical-x86_64-linux.iso.sha256

sudo cp latest-nixos-graphical-x86_64-linux.iso \
  /var/lib/libvirt/iso/latest-nixos-graphical-x86_64-linux.iso


virt-install \
  --connect qemu:///system \
  --name nixos \
  --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader.readony=yes,loader.type=pflash,nvram.template=/usr/share/OVMF/OVMF_VARS_4M.fd \
  --cdrom /var/lib/libvirt/iso/latest-nixos-graphical-x86_64-linux.iso \
  --disk pool=default,format=qcow2,bus=virtio,size=60 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant nixos-25.05 \
  --network network=host-network,model=virtio \
  --graphics spice \
  --video virtio \
  --sound ich9 \
  --rng /dev/urandom
```
