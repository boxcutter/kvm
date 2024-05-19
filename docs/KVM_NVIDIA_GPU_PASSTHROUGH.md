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


References:
https://github.com/lateralblast/kvm-nvidia-passthrough
