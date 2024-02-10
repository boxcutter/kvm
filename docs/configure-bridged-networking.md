## Configure bridged networking

All the networking options for kvm are just different configurations for a virtual networking
switch, also known as a bridge network interface.

The default network created when libvirt is used is called `default` and uses NAT. It normally
is configured to use a bridge network interface called `virbr0`. When a virtual machine is
on a NAT network, it is on a separate subnet that prevents outside access to the VM directly,
nwhile the VM itself can access any network the host can access.

With bridged networking, the VM will be on the same network as the host. It can be accessed
by all computers on your host network as if it were another computer directly connected to
the same network.

### Determine how the networking is configured on Ubuntu

Ubuntu has multiple methods for persisting network configurations, so first you need to
determine how the networking on your machine is configured. First check the current
configuration with the `ip link` command to get an overview of how the networking is
configured. Ultimiately everything in Linux is configured with the `ip` command, but
unfortunately there is not one standard way to persist a network configuration across
reboots.

On Ubuntu, determine if the host interface is managed by `systemd-networkd` or `NetworkManager`.
Usually if you are using Ubuntu Desktop, it's `NetworkManager`, and if you are using
Ubuntu Server, it's `systemd-networkd`, but it can vary.

Running `networkctl` will tell you is `systemd-networkd` is running and if an interface
is being managed. The default configuration on Ubuntu Desktop should show that
`systemd-networkd` is not running and the interfaces are not being managed (by `systemd-networkd`).

```
$ networkctl
WARNING: systemd-networkd is not running, output will be incomplete.

IDX LINK      TYPE     OPERATIONAL SETUP    
  1 lo        loopback n/a         unmanaged
  2 eno1      ether    n/a         unmanaged
  3 wlp0s20f3 wlan     n/a         unmanaged
  4 virbr0    bridge   n/a         unmanaged
  5 docker0   bridge   n/a         unmanaged

5 links listed.
```

By comparison, if `systemd-networkd` is running and interfaces are being managed, the
output of `networkctl` looks more like this:

```
$ networkctl
IDX LINK  TYPE     OPERATIONAL SETUP
  1 lo    loopback carrier     unmanaged
  2 ens33 ether    routable    configured

2 links listed.
```

You can check to see if NetworkManager is being used by using `nmcli`. If the network
interfaces are being managed by NetworkManager, the output will look something like
this:

```
$ nmcli general
STATE      CONNECTIVITY  WIFI-HW  WIFI     WWAN-HW  WWAN    
connected  full          enabled  enabled  enabled  enabled

$ nmcli connection
NAME                UUID                                  TYPE      DEVICE  
Wired connection 1  5297a82f-7244-31f3-9dad-c3fb49be0b33  ethernet  eno1    
docker0             80651a82-b1af-4ed7-a4bb-e0a802d6f012  bridge    docker0 
virbr0              d0da1989-df49-44dc-9c48-aa3c978fbb90  bridge    virbr0
```

But you're not done yet, you also need to check if netplan is being used to render
configurations in `systemd-networkd` or `NetworkManager`. In Ubuntu 24.04, there will
be a command called `netplan status` to check this. As of this writing, you are unlikely
to be using this, so instead the best way to check is to see if there are configuration
files in `/etc/netplan`. If `netplan` is being used on your system, it's probably
easiest to add the configuration for the bridge configuration through netplan.

Here's an example of a `systemd-networkd` configuration managed by `netplan`. It may
or may not include a `renderer` stanza that says `renderer: networkd`, because it is
the default:

```
$ ls /etc/netplan
00-installer-config.yaml
$ cat /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens33:
      dhcp4: true
  version: 2
```

On the other hand, if a `NetworkManager` configuration is being managed by `netplan`,
it will include a `renderer` stanza that says `renderer: NetworkManager`. It's not
unusual for there to be zero configuration in the actual netplan file, because currently,
NetworkManager isn't very well integrated into netplan on Ubuntu. You can't use
`netplan try` to experiment with new configurations, for example.

```
$ ls /etc/netplan/
01-network-manager-all.yaml
$ cat /etc/netplan/01-network-manager-all.yaml 
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
```

### Configuring bridged networking with systemd-networkd via Netplan

```
$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
ens33            UP             00:0c:29:b6:83:61 <BROADCAST,MULTICAST,UP,LOWER_UP>
```

```
$ ls /etc/netplan
00-installer-config.yaml
$ cat /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens33:
      dhcp4: true
  version: 2
```

```
# This is the network config written by 'subiquity'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: no
  bridges:
    br0:
      interfaces:
        - ens33
      dhcp4: yes
      parameters:
        stp: false
        forward-delay: 0
```

```
$ sudo netplan try
br0: reverting custom parameters for bridges and bonds is not supported

Please carefully review the configuration and use 'netplan apply' directly.
```

```
$ sudo netplan apply
$ networkctl
IDX LINK  TYPE     OPERATIONAL SETUP
  1 lo    loopback carrier     unmanaged
  2 ens33 ether    enslaved    configured
  3 br0   bridge   routable    configured

3 links listed.

$ ip -brief addr
lo               UNKNOWN        127.0.0.1/8 ::1/128
ens33            UP
br0              UP             172.25.0.112/22 metric 100 fe80::f4d4:91ff:feed:5e12/64
```

### Configuring bridged networking with NetworkManager via Netplan

```
$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
ens33            UP             00:0c:29:25:7e:47 <BROADCAST,MULTICAST,UP,LOWER_UP>

$ nmcli connection show --active
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  779e47c2-776a-3c0a-a498-ebffcbe374c4  ethernet  ens33 
```

```
$ ls /etc/netplan
01-network-manager-all.yaml
$ cat /etc/netplan/01-network-manager-all.yaml 
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
```

```
# This is the network config written by 'subiquity'
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ens33:
      dhcp4: no
  bridges:
    br0:
      interfaces:
        - ens33
      dhcp4: yes
      parameters:
        stp: false
        forward-delay: 0
```

```
$ sudo netplan try
br0: reverting custom parameters for bridges and bonds is not supported

Please carefully review the configuration and use 'netplan apply' directly.
```

```
$ sudo netplan apply
$ nmcli connection show --active
NAME           UUID                                  TYPE      DEVICE 
netplan-br0    00679506-5c05-3c3d-bdfe-474849762078  bridge    br0    
netplan-ens33  14f59568-5076-387a-aef6-10adfcca2e26  ethernet  ens33

$ ip addr show br0
3: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 0a:b1:59:e4:c8:e8 brd ff:ff:ff:ff:ff:ff
    inet 172.25.0.217/22 brd 172.25.3.255 scope global dynamic noprefixroute br0
       valid_lft 86334sec preferred_lft 86334sec
    inet6 fe80::8b1:59ff:fee4:c8e8/64 scope link 
       valid_lft forever preferred_lft forever
$ ip addr show ens33
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br0 state UP group default qlen 1000
    link/ether 00:0c:29:25:7e:47 brd ff:ff:ff:ff:ff:ff
    altname enp2s1
```

### Configuring bridged networking with NetworkManager

```
$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
ens33            UP             00:0c:29:25:7e:47 <BROADCAST,MULTICAST,UP,LOWER_UP>

$ nmcli connection show --active
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  779e47c2-776a-3c0a-a498-ebffcbe374c4  ethernet  ens33
```

```
# Create the brdige br0 with STP disable to avoid the bridge being advertised on the network
$ sudo nmcli connection add type bridge ifname br0 stp no
# Swing the ethernet interface to the bridge
$ sudo nmcli connection add type bridge-slave ifname ens33 master br0
```

```
$ nmcli connection show
NAME                UUID                                  TYPE      DEVICE 
bridge-br0          5eb86a64-f791-4c32-a421-a256e2f1cdb2  bridge    br0    
Wired connection 1  779e47c2-776a-3c0a-a498-ebffcbe374c4  ethernet  ens33  
bridge-slave-ens33  0222534a-92a7-4b57-bd14-32e5bc44b73b  ethernet  --
```

```
# Bring the existing connection down
$ sudo nmcli connection down 'Wired connection 1'
# Bring the new bridge up
$ sudo nmcli connection up bridge-br0
$ sudo nmcli connection up bridge-slave-ens33
```

```
$ nmcli connection show --active
NAME                UUID                                  TYPE      DEVICE 
bridge-br0          5eb86a64-f791-4c32-a421-a256e2f1cdb2  bridge    br0    
bridge-slave-ens33  0222534a-92a7-4b57-bd14-32e5bc44b73b  ethernet  ens33

$ ip addr show br0
3: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 0a:b1:59:e4:c8:e8 brd ff:ff:ff:ff:ff:ff
    inet 172.25.0.217/22 brd 172.25.3.255 scope global dynamic noprefixroute br0
       valid_lft 86293sec preferred_lft 86293sec
    inet6 fe80::524c:23ad:bd19:2d38/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever

$ ip addr show ens33
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br0 state UP group default qlen 1000
    link/ether 00:0c:29:25:7e:47 brd ff:ff:ff:ff:ff:ff
    altname enp2s1
```

### Configuring bridged networking with the ip command

It can be helpful to configure bridged networking with the iproute2 `ip` command.
iproute2 is now the default networking toolkit in Linux, replacing `net-tools` commands
like `ifconfig`, `brctl` and `route` with a more unified interface.

The configuration will not be persist across reboots without putting the commands in
a script, but it's a great way to test the bridged networking setup initially so
that you can sort out any issues.

NOTE: It's difficult to configure bridge networking on a remote server interactively.
Be careful about trying to run these commands on a remote server. You may inadvertently
disconnect yourself from the remote server during configuration and you may not be able
to recover without power cycling the remote machine.

First, list all your network interfaces with `ip -brief link` and decide what interface
you want to use for your VMs to have connectivity to the outside world. This interface
will act as the default gateway for a group of virtual machines. It needs to be an
interface whose state is `up`. Here's an example of what the output looks like.

```
$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
ens33            UP             00:0c:29:b6:83:61 <BROADCAST,MULTICAST,UP,LOWER_UP>
```

Create the bridge:

```
# create a network bridge interface named br0 and change its state to up
$ sudo ip link add name br0 type bridge
$ sudo ip link set dev br0 up
$ ip link show br0
$ sudo ip link set eno1 master br0
```

Assign a network address to the bridge and swing the ethernet interface to the bridge.

```
$ ip route show default
default via 172.25.0.1 dev ens33 proto dhcp src 172.25.3.252 metric 100
$ ip -brief addr show ens33
ens33            UP             172.25.3.252/22 metric 100 fe80::20c:29ff:feb6:8361/64
$ sudo ip address add 172.25.3.252/22 dev br0
$ sudo ip route append default via 172.25.0.1 dev br0
$ sudo ip link set ens33 master br0
$ sudo ip address del 172.25.3.252/22 dev ens33
# Now you should see that ens01 is getting an IP address through br0
$ ip addr show ens33
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br0 state UP group default qlen 1000
    link/ether 00:0c:29:b6:83:61 brd ff:ff:ff:ff:ff:ff
    altname enp2s1
    inet6 fe80::20c:29ff:feb6:8361/64 scope link
       valid_lft forever preferred_lft forever
$ ip addr show br0
3: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether f6:d4:91:ed:5e:12 brd ff:ff:ff:ff:ff:ff
    inet 172.25.3.252/22 scope global br0
       valid_lft forever preferred_lft forever
    inet6 fe80::f4d4:91ff:feed:5e12/64 scope link
       valid_lft forever preferred_lft forever
```

References:
Arch wiki: https://wiki.archlinux.org/title/network_bridge
