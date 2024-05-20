# NVIDIA GPU Passthrough with KVM

Determine Nvidia PIC IDs:
```
$ lspci | grep -i nvidia
1b:00.0 VGA compatible controller: NVIDIA Corporation TU102GL [Quadro RTX 6000/8000] (rev a1)
1b:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
1b:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1)
1b:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
1c:00.0 VGA compatible controller: NVIDIA Corporation TU102GL [Quadro RTX 6000/8000] (rev a1)
1c:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
1c:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1)
1c:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
1d:00.0 VGA compatible controller: NVIDIA Corporation TU102GL [Quadro RTX 6000/8000] (rev a1)
1d:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
1d:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1)
1d:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
1e:00.0 VGA compatible controller: NVIDIA Corporation TU102GL [Quadro RTX 6000/8000] (rev a1)
1e:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
1e:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1)
1e:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
3d:00.0 VGA compatible controller: NVIDIA Corporation TU102GL [Quadro RTX 6000/8000] (rev a1)
3d:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
3d:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1)
3d:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
3f:00.0 VGA compatible controller: NVIDIA Corporation TU102GL [Quadro RTX 6000/8000] (rev a1)
3f:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
3f:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1)
3f:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
40:00.0 VGA compatible controller: NVIDIA Corporation TU102GL [Quadro RTX 6000/8000] (rev a1)
40:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
40:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1)
40:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
41:00.0 VGA compatible controller: NVIDIA Corporation TU102GL [Quadro RTX 6000/8000] (rev a1)
41:00.1 Audio device: NVIDIA Corporation TU102 High Definition Audio Controller (rev a1)
41:00.2 USB controller: NVIDIA Corporation TU102 USB 3.1 Host Controller (rev a1)
41:00.3 Serial bus controller: NVIDIA Corporation TU102 USB Type-C UCSI Controller (rev a1)
```

Determine Nvidia PCI Device IDs
```
#!/bin/bash

# Get the output of `lspci | grep -i nvidia`
output=$(lspci | grep -i nvidia)

# Loop through each line of the output
echo "$output" | while read -r line; do
  # Extract the first column (PCI identifier)
  pci_id=$(echo "$line" | awk '{print $1}')
  
  # Construct the command
  cmd="lspci -ns $pci_id | awk '{print \$3}'"
  
  # Print the command
  echo "$cmd"
  
  # Run the command and print the output
  eval "$cmd"
done
```

```
$ lspci -ns 1b:00.0 | awk '{print $3}'
10de:1e30
$ lspci -ns 1b:00.1 | awk '{print $3}'
10de:10f7
$ lspci -ns 1b:00.2 | awk '{print $3}'
10de:1ad6
$ lspci -ns 1b:00.3 | awk '{print $3}'
10de:1ad7
$ lspci -ns 1c:00.0 | awk '{print $3}'
10de:1e30
$ lspci -ns 1c:00.1 | awk '{print $3}'
10de:10f7
$ lspci -ns 1c:00.2 | awk '{print $3}'
10de:1ad6
$ lspci -ns 1c:00.3 | awk '{print $3}'
10de:1ad7
$ lspci -ns 1d:00.0 | awk '{print $3}'
10de:1e30
$ lspci -ns 1d:00.1 | awk '{print $3}'
10de:10f7
$ lspci -ns 1d:00.2 | awk '{print $3}'
10de:1ad6
$ lspci -ns 1d:00.3 | awk '{print $3}'
10de:1ad7
$ lspci -ns 1e:00.0 | awk '{print $3}'
10de:1e30
$ lspci -ns 1e:00.1 | awk '{print $3}'
10de:10f7
$ lspci -ns 1e:00.2 | awk '{print $3}'
10de:1ad6
$ lspci -ns 1e:00.3 | awk '{print $3}'
10de:1ad7
$ lspci -ns 3d:00.0 | awk '{print $3}'
10de:1e30
$ lspci -ns 3d:00.1 | awk '{print $3}'
10de:10f7
$ lspci -ns 3d:00.2 | awk '{print $3}'
10de:1ad6
$ lspci -ns 3d:00.3 | awk '{print $3}'
10de:1ad7
$ lspci -ns 3f:00.0 | awk '{print $3}'
10de:1e30
$ lspci -ns 3f:00.1 | awk '{print $3}'
10de:10f7
$ lspci -ns 3f:00.2 | awk '{print $3}'
10de:1ad6
$ lspci -ns 3f:00.3 | awk '{print $3}'
10de:1ad7
$ lspci -ns 40:00.0 | awk '{print $3}'
10de:1e30
$ lspci -ns 40:00.1 | awk '{print $3}'
10de:10f7
$ lspci -ns 40:00.2 | awk '{print $3}'
10de:1ad6
$ lspci -ns 40:00.3 | awk '{print $3}'
10de:1ad7
$ lspci -ns 41:00.0 | awk '{print $3}'
10de:1e30
$ lspci -ns 41:00.1 | awk '{print $3}'
10de:10f7
$ lspci -ns 41:00.2 | awk '{print $3}'
10de:1ad6
$ lspci -ns 41:00.3 | awk '{print $3}'
10de:1ad7
```

Enable IOMMU and pass management of devices to vfio in GRUB:
```
cat /etc/default/grub |grep iommu
GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt intremap=no_x2apic_optout vfio-pci.ids=10de:1e30,10de:10f7,10de:1ad6,10de:1ad7"
```

Update GRUB:
```
sudo update-grub
```

Disable nvidia drivers:
```
$ sudo sh -c 'echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf'
$ sudo sh -c 'echo "blacklist nvidia_uvm" >> /etc/modprobe.d/blacklist.conf'
$ sudo sh -c 'echo "blacklist nvidia_drm" >> /etc/modprobe.d/blacklist.conf'
$ sudo sh -c 'echo "blacklist nvidia_modeset" >> /etc/modprobe.d/blacklist.conf'
$ sudo sh -c 'echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf'
```

Update vfio config:
```
$ sudo sh -c 'echo "options vfio-pci ids=10de:1e30,10de:10f7,10de:1ad6,10de:1ad7 disable_vga=1" > /etc/modprobe.d/vfio.conf'
```

Reboot
```
$ sudo reboot
```

After reboot you should see vfio mention the PCI ID of the Nvidia GPU in dmesg or /proc/interrupts:
```
$ sudo dmesg | grep vfio | grep add
[    5.486982] vfio_pci: add [10de:1e30[ffffffff:ffffffff]] class 0x000000/00000000
[    5.651136] vfio_pci: add [10de:10f7[ffffffff:ffffffff]] class 0x000000/00000000
[    5.819195] vfio_pci: add [10de:1ad6[ffffffff:ffffffff]] class 0x000000/00000000
[    5.987086] vfio_pci: add [10de:1ad7[ffffffff:ffffffff]] class 0x000000/00000000
```

## Ubuntu 24.04 Server

```
virt-install \
  --connect qemu:///system \
  --name gpu-ubuntu-server-2204 \
  --boot uefi \
  --memory 16384 \
  --vcpus 4 \
  --disk pool=default,size=50,bus=virtio,format=qcow2 \
  --cdrom /var/lib/libvirt/iso/ubuntu-22.04.4-live-server-amd64.iso \
  --os-variant ubuntu22.04 \
  --network network=host-bridge,model=virtio \
  --graphics vnc,listen=0.0.0.0,password=foobar \
  --noautoconsole \
  --console pty,target_type=serial \
  --cpu host-passthrough \
  --machine q35 \
  --host-device 41:00.0 \
  --features kvm_hidden=on \
  --virt-type kvm \
  --debug \
  --noreboot

$ virsh vncdisplay gpu-ubuntu-server-2204
:0
$ virsh dumpxml gpu-ubuntu-server-2204 | grep "graphics type='vnc'"
    <graphics type='vnc' port='5900' autoport='yes' listen='0.0.0.0'>

# vnc to server on port  to complete install
# Get the IP address of the default host interface
ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
# Use a vnc client to connect to `vnc://<host_ip>:5900`
# When the install is complete the VM will be shut down

$ virsh domblklist gpu-ubuntu-server-2204
 Target   Source
---------------------------------------------------------------------
 vda      /var/lib/libvirt/images/gpu-ubuntu-server-2204.qcow2
 sda      /var/lib/libvirt/iso/ubuntu-22.04.4-live-server-amd64.iso

$ virsh change-media gpu-ubuntu-server-2204 sda --eject
Successfully ejected media.

# Reconfigure VNC
virsh edit gpu-ubuntu-server-2204
<graphics type='vnc' port='-1' autoport='yes' listen='127.0.0.1' passwd='foobar'/>
<graphics type='none'/>
virsh restart ubuntu-desktop-2204

# Install acpi or qemu-guest-agent in the vm so that
# 'virsh shutdown <image>' works
$ sudo apt-get update
$ sudo apt-get install qemu-guest-agent

# enable serial service in VM
sudo systemctl enable --now serial-getty@ttyS0.service

$ sudo lshw -C display
  *-display
       description: Display controller
       product: bochs-drmdrmfb
       physical id: 1
       bus info: pci@0000:00:01.0
       logical name: /dev/fb0
       version: 02
       width: 32 bits
       clock: 33MHz
       capabilities: pciexpress bus_master cap_list rom fb
       configuration: depth=32 driver=bochs-drm latency=0 resolution=1024,768
       resources: irq:0 memory:c0000000-c0ffffff memory:c348f000-c348ffff memory:80200000-80207fff
  *-display UNCLAIMED
       description: VGA compatible controller
       product: TU102GL [Quadro RTX 6000/8000]
       vendor: NVIDIA Corporation
       physical id: 0
       bus info: pci@0000:05:00.0
       version: a1
       width: 64 bits
       clock: 33MHz
       capabilities: pm msi pciexpress vga_controller bus_master cap_list
       configuration: latency=0
       resources: iomemory:80-7f iomemory:80-7f memory:c1000000-c1ffffff memory:800000000-80fffffff memory:810000000-811ffffff ioport:e000(size=128)

# nVidia Quadro RTX 8000
sudo apt-get install nvidia-driver-535 nvidia-dkms-535
```


References:
https://github.com/lateralblast/kvm-nvidia-passthrough
