# QEMU/KVM Install for NVDIA Jetson Platform

Install QEMU/KVM and libvirtd 

```bash
apt-get update
sudo apt-get update
sudo apt-get install qemu-kvm libvirt-daemon-system
# if you want to install images from ISOs with virt-install
sudo apt-get install virtinst
```

Make sure the current user is a member of the libvirt and kvm groups

```bash
$ sudo adduser $(id -un) libvirt
Adding user '<username>' to group 'libvirt' ...
$ sudo adduser $(id -un) kvm
Adding user '<username>' to group 'kvm' ...
```

Run `virt-host-validate` to check the setup:

```bash
$ virt-host-validate qemu
  QEMU: Checking if device /dev/kvm exists                                   : PASS
  QEMU: Checking if device /dev/kvm is accessible                            : PASS
  QEMU: Checking if device /dev/vhost-net exists                             : WARN (Load the 'vhost_net' module to improve performance of virtio networking)
  QEMU: Checking if device /dev/net/tun exists                               : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : WARN (Enable 'devices' in kernel Kconfig file or mount/enable cgroup controller in your system)
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for device assignment IOMMU support                         : WARN (Unknown if this platform has IOMMU support)
  QEMU: Checking for secure guest support                                    : WARN (Unknown if this platform has Secure Guest support)

# The vhost_net module does not appear to be present in the default Linux for Tegra kernel

# There's no grub on arm64, boot options are controlled by /boot/extlinux/extlinux.conf
# But doesn't appear that it's possible to enable devices support
# sudo cp /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.orig
# APPEND root=/dev/sda1 rw cgroup_enable=memory,cgroup_enable=cpu,cgroup_enable=devices cgroup_memory=1
```

Reboot to restart the QEMU/KVM daemon

```bash
sudo restart
```

Configure bridged networking

```
$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
can0             DOWN           <NOARP,ECHO> 
can1             DOWN           <NOARP,ECHO> 
wlan0            UP             b4:8c:9d:1c:59:cb <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth0             UP             48:b0:2d:dc:cc:a5 <BROADCAST,MULTICAST,UP,LOWER_UP> 
l4tbr0           DOWN           3e:c7:e7:79:f3:87 <BROADCAST,MULTICAST> 
usb0             DOWN           4a:cc:c0:ee:72:85 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
usb1             DOWN           4a:cc:c0:ee:72:87 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
virbr0           DOWN           52:54:00:db:7e:78 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
docker0          DOWN           02:42:92:48:71:3d <NO-CARRIER,BROADCAST,MULTICAST,UP>

$ nmcli connection show
NAME                UUID                                  TYPE      DEVICE  
Wired connection 1  bde1a0a0-8fd9-3eb3-acb5-17fe609b124e  ethernet  eth0    
Dreamfall           266ae331-63c7-4f90-9f8b-68ce24868245  wifi      wlan0   
docker0             1f351718-5833-46fe-a8ad-ba119dd90723  bridge    docker0 
virbr0              bde3a162-949a-4665-a88f-fe2e65e5e07b  bridge    virbr0
```

```
# Create the bridge br0 with STP disabled to avoid the bridge being advertised on the network
$ sudo nmcli connection add type bridge ifname br0 stp no
# Swing the ethernet interface to the bridge
$ sudo nmcli connection add type bridge-slave ifname eth0 master br0
```

```
# Bring the existing connection down
$ sudo nmcli connection down 'Wired connection 1'
# Bring the new bridge up
$ sudo nmcli connection up bridge-br0
$ sudo nmcli connection up bridge-slave-eth0

$ nmcli c
NAME                UUID                                  TYPE      DEVICE  
bridge-br0          27c2851c-e0d1-4606-91ba-526c79316273  bridge    br0     
Dreamfall           266ae331-63c7-4f90-9f8b-68ce24868245  wifi      wlan0   
docker0             1f351718-5833-46fe-a8ad-ba119dd90723  bridge    docker0 
virbr0              bde3a162-949a-4665-a88f-fe2e65e5e07b  bridge    virbr0  
bridge-slave-eth0   8be31a75-923c-47ed-8256-bc9d82d4aa12  ethernet  eth0    
Wired connection 1  bde1a0a0-8fd9-3eb3-acb5-17fe609b124e  ethernet  --  
```

Add bridged interface to DOCKER-USER chain
```
# https://serverfault.com/questions/963759/docker-breaks-libvirt-bridge-network
# https://docs.docker.com/network/packet-filtering-firewalls/
sudo iptables -I DOCKER-USER -i br0 -o br0 -j ACCEPT
# verify chain
sudo iptables -L DOCKER-USER -v -n
# verify it works, then save the rules
sudo apt-get update
sudo apt-get install iptables-persistent
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
```

```
# Network Manager
sudo nmcli con show
sudo nmcli device status
# Add a new bridge
sudo nmcli con add ifname br0 type bridge con-name br0
# Bring the bridge interface up
sudo nmcli con up br0
# Attach network interfaces to the bridge
sudo nmcli con add type bridge-slave ifname eth0 master br0
# Bring up the bridge-slave connection
sudo nmcli con up br0
# Use DHCP
sudo nmcli con modify br0 ipv4.method auto
sudo nmcli con up br0
# set forward delay
sudo nmcli con modify br0 bridge.stp no
sudo nmcli con modify br0 bridge.forward-delay 3
#
sudo nmcli con down "Wired connection 1"
sudo nmcli con up br0
sudo reboot
```
