# Nvidia Jetson Embedded Computing Board Manual Setup

Nvidia Jetson embedded computer boards are used on robots and drones to
behave as smart cameras.

Helpful video from JetsonHacks YouTube channel on unboxing and setup:
https://www.youtube.com/watch?v=LUxyNyCl4ro

The base still leaves most of the carrier board exposed. StereoLabs sells a
metal enclosure that also has room for their capture  board:
https://store.stereolabs.com/products/enclosure-for-orin-agx-devkit

The only way to connect a display to the AGX Orin Developer Kit is via
DisplayPort. If you need HDMI output, you’ll need to have a
DisplayPort (male) to HDMI (female) adapter handy.

The Orin can be powered via USB-C on the back, or with the included power
brick and a barrel connector.

Moving towards minimizing the desktop GUI that comes with the developer
kit when it ships to basically run Ubuntu server instead of desktop:

https://nvidia-ai-iot.github.io/jetson-min-disk/step1.html

A USB timeout error may occur during flashing. The following error indicates that your flash host’s USB port is not enabled:

```
[ 0.1172 ] Sending bct_br
[ 0.1603 ] ERROR: might be timeout in USB write.
Error: Return value
```

1. First try changing the USB port:
  a. Move to a different USB port, if available.
  b. Power cycle the AGX and retry flashing.
2. If that doesn’t work, try disabling autosuspend:
  a. To disable `autosuspend` on your host’s USB ports, run the following command.
    ```
    sudo bash -c 'echo -1 > /sys/module/usbcore/parameters/autosuspend'
    ```
  b. Power cycle the AGX and retry flashing.

> **Note**
> This error does not clear until you power cycle the AGX, so don’t skip that step.

https://forums.developer.nvidia.com/t/jetson-agx-orin-faq/237459

## First steps - verify the Jetson is booting off NVMe and has at least 2TB of storage

### Verify that JetPack 6.2.x (or higher) is present

If you think your Jetson Developer Kit has already been configured, double
check to make sure the system has the desired JetPack version and there is
adequate storage.

Make sure that you installed the right version of the OS - currently we prefer 
Ubuntu 22.04 with JetPack 6.2 (or higher). Earlier versions of JetPack 6.x had issues
with kvm virtual machine network performance, so we don't use these earlier
versions of 6.x.

```bash
$ cat /etc/os-release
PRETTY_NAME="Ubuntu 22.04.5 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.5 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy

$ cat /etc/nv_tegra_release
# R36 (release), REVISION: 4.3, GCID: 38968081, BOARD: generic, EABI: aarch64, DATE: Wed Jan  8 01:49:37 UTC 2025
# KERNEL_VARIANT: oot
TARGET_USERSPACE_LIB_DIR=nvidia
TARGET_USERSPACE_LIB_DIR_PATH=usr/lib/aarch64-linux-gnu/nvidia

$ sudo apt-cache show nvidia-jetpack
[sudo] password for automat:
Sorry, try again.
[sudo] password for automat:
Package: nvidia-jetpack
Source: nvidia-jetpack (6.2)
Version: 6.2+b77
Architecture: arm64
Maintainer: NVIDIA Corporation
Installed-Size: 194
Depends: nvidia-jetpack-runtime (= 6.2+b77), nvidia-jetpack-dev (= 6.2+b77)
Homepage: http://developer.nvidia.com/jetson
Priority: standard
Section: metapackages
Filename: pool/main/n/nvidia-jetpack/nvidia-jetpack_6.2+b77_arm64.deb
Size: 29298
SHA256: 70553d4b5a802057f9436677ef8ce255db386fd3b5d24ff2c0a8ec0e485c59cd
SHA1: 9deab64d12eef0e788471e05856c84bf2a0cf6e6
MD5sum: 4db65dc36434fe1f84176843384aee23
Description: NVIDIA Jetpack Meta Package
Description-md5: ad1462289bdbc54909ae109d1d32c0a8

Package: nvidia-jetpack
Source: nvidia-jetpack (6.1)
Version: 6.1+b123
Architecture: arm64
Maintainer: NVIDIA Corporation
Installed-Size: 194
Depends: nvidia-jetpack-runtime (= 6.1+b123), nvidia-jetpack-dev (= 6.1+b123)
Homepage: http://developer.nvidia.com/jetson
Priority: standard
Section: metapackages
Filename: pool/main/n/nvidia-jetpack/nvidia-jetpack_6.1+b123_arm64.deb
Size: 29312
SHA256: b6475a6108aeabc5b16af7c102162b7c46c36361239fef6293535d05ee2c2929
SHA1: f0984a6272c8f3a70ae14cb2ca6716b8c1a09543
MD5sum: a167745e1d88a8d7597454c8003fa9a4
Description: NVIDIA Jetpack Meta Package
Description-md5: ad1462289bdbc54909ae109d1d32c0a8

automat@agx01:~$ sudo apt-cache show nvidia-jetpack
Package: nvidia-jetpack
Source: nvidia-jetpack (6.2)
Version: 6.2+b77
Architecture: arm64
Maintainer: NVIDIA Corporation
Installed-Size: 194
Depends: nvidia-jetpack-runtime (= 6.2+b77), nvidia-jetpack-dev (= 6.2+b77)
Homepage: http://developer.nvidia.com/jetson
Priority: standard
Section: metapackages
Filename: pool/main/n/nvidia-jetpack/nvidia-jetpack_6.2+b77_arm64.deb
Size: 29298
SHA256: 70553d4b5a802057f9436677ef8ce255db386fd3b5d24ff2c0a8ec0e485c59cd
SHA1: 9deab64d12eef0e788471e05856c84bf2a0cf6e6
MD5sum: 4db65dc36434fe1f84176843384aee23
Description: NVIDIA Jetpack Meta Package
Description-md5: ad1462289bdbc54909ae109d1d32c0a8

Package: nvidia-jetpack
Source: nvidia-jetpack (6.1)
Version: 6.1+b123
Architecture: arm64
Maintainer: NVIDIA Corporation
Installed-Size: 194
Depends: nvidia-jetpack-runtime (= 6.1+b123), nvidia-jetpack-dev (= 6.1+b123)
Homepage: http://developer.nvidia.com/jetson
Priority: standard
Section: metapackages
Filename: pool/main/n/nvidia-jetpack/nvidia-jetpack_6.1+b123_arm64.deb
Size: 29312
SHA256: b6475a6108aeabc5b16af7c102162b7c46c36361239fef6293535d05ee2c2929
SHA1: f0984a6272c8f3a70ae14cb2ca6716b8c1a09543
MD5sum: a167745e1d88a8d7597454c8003fa9a4
Description: NVIDIA Jetpack Meta Package
Description-md5: ad1462289bdbc54909ae109d1d32c0a8
```

### Verify that the boot drive is the NVMe device

```bash
# Install efibootmgr if it is not already installed
$ sudo apt-get update
$ sudo apt-get install efibootmgr
# NVMe should be first in the boot order
$ efibootmgr
BootCurrent: 0001
Timeout: 5 seconds
BootOrder: 0001,0000,0002,0003,0004,0005,0006,0007,0008
Boot0000* Enter Setup
Boot0001* UEFI Samsung SSD 990 PRO 4TB S7KGNJ0WC15702M 1
Boot0002* UEFI eMMC Device
Boot0003* UEFI PXEv4 (MAC:48B02DDCCCA5)
Boot0004* UEFI PXEv6 (MAC:48B02DDCCCA5)
Boot0005* UEFI HTTPv4 (MAC:48B02DDCCCA5)
Boot0006* UEFI HTTPv6 (MAC:48B02DDCCCA5)
Boot0007* BootManagerMenuApp
Boot0008* UEFI Shell
```

## Remedy - install an NVMe drive and flash with SDK Manager

The Jetson Developer Kits are configured to boot and run the OS off the
built-in eMMC drive. The eMMC drive is fairly small, and eMMC is slow. So
it is better to just reconfigure the system so it boots off the secondary
NVMe drive exclusively and ignores the eMMC device. (However the eMMC can
be used as a secondary boot partition for disaster recovery).

You’ll need a second x86_64 intel PC running [NVIDIA SDK Manager](https://developer.nvidia.com/sdk-manager)
to flash the device and install JetPack on NVMe drive:

![SDKManager](https://github.com/boxcutter/kvm/blob/86f958179b356a7bf7b73f1fb381fdec8a67b52b/docs/images/jetpack6/Jan2021-developer-sdkm-landing-page-web-diagram.jpg)

The second x86_64 intel PC should be running Ubuntu 20.04. An Ubuntu 20.04
host system can flash a target NVIDIA device with either JetPack 6.x or
JetPack 5.x. We work with both versions of JetPack (even though now we prefer
JetPack 6.x):

![SDKManager system compatibility matrix](https://github.com/boxcutter/kvm/blob/d21e40166522408f1e5ff2bc73f0e218ea60ed3d/docs/images/jetpack6/Screenshot%202024-05-11%20at%2016.55.34.png)

Go to the Nvidia SDK Manager web site:
https://developer.nvidia.com/sdk-manager

Choose to download the NVIDIA SDK Manager .deb package:

![Download SDKManager deb](https://github.com/boxcutter/kvm/blob/95f24225a425a77e38073caf3544e9c694b0ef3c/docs/images/jetpack6/IMG_4862.PNG)

You’ll need to create an NVDIA account to download:

![Log in or sign up for an NVIDIA account](https://github.com/boxcutter/kvm/blob/2a2647f3636bdeb0dddd626075c43ee745f65d07/docs/images/jetpack6/IMG_4864.PNG)

Install the SDK Manager:

`sudo apt-get install ./sdkmanager_[version]-[build#]_amd64.deb`

Then start the SDK Manager with:

`/opt/nvidia/sdkmanager/sdkmanager`

Login with your NVIDIA Developer login again to access the OS boot files:

![NVIDIA Developer Login](https://github.com/boxcutter/kvm/blob/aa13c8d35dfe10b335796869860adc6871a83ea9/docs/images/jetpack6/IMG_4865.PNG)

It will pop up a separate web browser for you to login with your account

![NVIDIA login in SDK Manager](https://github.com/boxcutter/kvm/blob/aa13c8d35dfe10b335796869860adc6871a83ea9/docs/images/jetpack6/IMG_4866.PNG)

Once you are authenticated, you can close the login window and use SDK
Manager.

Over in the SDK Manager app a private notice will be displayed, make a
selection and click on the "OK" button.

![Privacy Notice](https://github.com/boxcutter/kvm/blob/aa13c8d35dfe10b335796869860adc6871a83ea9/docs/images/jetpack6/IMG_4868.PNG)

You’ll need to run a USB-C cable from the Ubuntu 20.04 Intel host machine
to the Nvidia Jetson. Connect the USB-C cable for the intel host machine
to the USB-C port on the side with the 40-pin connector (as it supports
both upstream and downstream data):

https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/developer_kit_layout.html

![Flashing port](https://github.com/boxcutter/kvm/blob/bc9414424f13147a6de3cd41e130a2f11c426f6b/docs/images/jetpack6/2024-02-03_08-55-58.png)

Connect to the target hardware from your host to the flashing port with a USB-C cable.

When you run SDK Manager with `/opt/nvidia/sdkmanager/sdkmanager` it may detect the
target hardware automatically:

![SDK Manager detected device](https://github.com/boxcutter/kvm/blob/8b5793a6120ba6bda748dbf65c8ea937de4f86fb/docs/images/jetpack6/IMG_4876.PNG)

In Step One - System Configuration, verify that the Host Machine is Ubuntu 20.04
- x86_64 - if not, make sure you’re running on a machine with this configuration!
- And then make sure the correct target hardware is configured. Choose the JetPack
- version to install. Click on the "Continue to Step 02" button.

![Step One](https://github.com/boxcutter/kvm/blob/1eaaaffd694ede36c3ba680bc0e675780010a325/docs/images/jetpack6/IMG_4877.PNG)

Choose the appropriate SDK components in Step Two. You can also choose to download
now and install later and store the install files on a shared drive. Click on the
"Continue to Step 03" button.

![Step Two](https://github.com/boxcutter/kvm/blob/8c035a3f137df1e665c5bd3b0b4cf9c94fa90cb7/docs/images/jetpack6/IMG_5006.PNG)

It will then proceed to download the files for the JetPack version you created -
will take 15-20 minutes or more depending on the speed of your internet connection:

Once the download is complete you’ll need to put the Jetson target hardware into recovery mode to proceed:

![SDK Manager is about to flash your Jetson AGX Orin module](https://github.com/boxcutter/kvm/blob/8c035a3f137df1e665c5bd3b0b4cf9c94fa90cb7/docs/images/jetpack6/IMG_5008.PNG)

Follow the instructions displayed in the dialog accordingly.

I usually prefer to use manual mode (but automatic mode is fine as well) - if
you’re in automatic mode, then you’ll need to hook up a monitor to the Jetson
to get its IP address (and it has to have an OS already installed).

To put the device into target recovery mode:
https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/developer_kit_layout.html

1. Power off the device holding down the (1) Power button for 10-15 seconds.
2. Make sure the device is powered off, but still connected to the host PC by
   the USB-C cable.
3. Press and hold (2) "Force recovery button" (the middle button) while also
   pressing the (3) "Reset button" (the right button). Then release both buttons.

You may also need to make sure that you disconnect the display adapter and/or keyboard
on the Jetson if JetPack is already configured to ensure the system will flash via
recovery mode.

![Force Recovery](https://github.com/boxcutter/kvm/blob/ac9385b0b1e7772127945f21f23491f22184d7e4/docs/images/jetpack6/Screenshot%202024-05-11%20at%2018.15.07.png)

Once the host detects the device in recovery mode, you'll need to choose the
target device type again:
![Force Recovery Device Detected](https://github.com/boxcutter/kvm/blob/d1bc0358ab729c21cbd1bd511ed003ffeed6c071/docs/images/jetpack6/IMG_4999.PNG)

## Ubuntu Configuration on Target Device 

After the device is detected and refreshed, choose "Runtime configuration".
When you select Runtime configuration, you'll be able to manually complete
the Ubuntu System Configuration, selecting the default username, time zone,
etc.

Choose the NVMe drive as the target storage device and click on the "Flash"
button to continue:
https://docs.nvidia.com/sdk-manager/install-with-sdkm-jetson/index.html

![Runtime configuration](https://github.com/boxcutter/kvm/blob/d1bc0358ab729c21cbd1bd511ed003ffeed6c071/docs/images/jetpack6/IMG_5015.PNG)

SDK Manager will then continue to flash the device and install the Ubuntu
on the NVMe drive:

![Installing](https://github.com/boxcutter/kvm/blob/d1bc0358ab729c21cbd1bd511ed003ffeed6c071/docs/images/jetpack6/IMG_5017.PNG)

After the flashing step finishes and the device reboots, it will again prompt for the device type. Choose accordingly and click on OK.

![Device Type Again](https://github.com/boxcutter/kvm/blob/d1bc0358ab729c21cbd1bd511ed003ffeed6c071/docs/images/jetpack6/IMG_4999.PNG)

Now you’ll need hop over to the Jetson, set up a monitor on the Jetson,
and complete the system configuration for Ubuntu.

Accept the license terms:

![Terms and Conditions](https://github.com/boxcutter/kvm/blob/a555af83c41a36ee726d1a55dcf59cdaa0973ca1/docs/images/jetpack6/IMG_5019.PNG)

Choose the language:

![Language](https://github.com/boxcutter/kvm/blob/a555af83c41a36ee726d1a55dcf59cdaa0973ca1/docs/images/jetpack6/IMG_5020.PNG)

Choose the keyboard:

![Keyboard](https://github.com/boxcutter/kvm/blob/a555af83c41a36ee726d1a55dcf59cdaa0973ca1/docs/images/jetpack6/IMG_5021.PNG)

Choose the time zone:

![Time Zone](https://github.com/boxcutter/kvm/blob/a555af83c41a36ee726d1a55dcf59cdaa0973ca1/docs/images/jetpack6/IMG_5022.PNG)

Set up the default user:

![User prompt](https://github.com/boxcutter/kvm/blob/a555af83c41a36ee726d1a55dcf59cdaa0973ca1/docs/images/jetpack6/IMG_5023.PNG)

Here's the values we normally use for the user account. We
use the provisioning user name `automat` and the hostname
`agx0x1`:

![automat](https://github.com/boxcutter/kvm/blob/a555af83c41a36ee726d1a55dcf59cdaa0973ca1/docs/images/jetpack6/IMG_5025.PNG)

Choose whether or not to install the Chromium browser. You'll
need to make sure there's a working network connection if you
do choose to install:

![chromium](https://github.com/boxcutter/kvm/blob/a555af83c41a36ee726d1a55dcf59cdaa0973ca1/docs/images/jetpack6/IMG_5026.PNG)

Then the system configuration completes and you'll need to
go through the standard Ubuntu desktop user setup:

Choose whether or not to connect online accounts:

![online accounts](https://github.com/boxcutter/kvm/blob/98514b819f2318f22af1734f87cf629718624201/docs/images/jetpack6/IMG_5033.PNG)

Choose whether or not to enable Ubuntu Pro:

![Ubuntu Pro](https://github.com/boxcutter/kvm/blob/98514b819f2318f22af1734f87cf629718624201/docs/images/jetpack6/IMG_5034.PNG)

Choose whether or not to help improve Ubuntu:

![Help improve Ubuntu](https://github.com/boxcutter/kvm/blob/98514b819f2318f22af1734f87cf629718624201/docs/images/jetpack6/IMG_5035.PNG)

Choose whether or not to enable location services:

![Location services](https://github.com/boxcutter/kvm/blob/98514b819f2318f22af1734f87cf629718624201/docs/images/jetpack6/IMG_5037.PNG)

Click to get past the final step:

![Ready to go](https://github.com/boxcutter/kvm/blob/98514b819f2318f22af1734f87cf629718624201/docs/images/jetpack6/IMG_5038.PNG)

And finally you should see the Ubuntu desktop:

![Desktop](https://github.com/boxcutter/kvm/blob/98514b819f2318f22af1734f87cf629718624201/docs/images/jetpack6/IMG_5039.PNG)

## Install SDK Components

Hop on back over to your Intel provisioning host to complete the final
step of the install. This step is optional.

You may get prompted for the target device type again, choose accordingly:

![Device Type Again](https://github.com/boxcutter/kvm/blob/d1bc0358ab729c21cbd1bd511ed003ffeed6c071/docs/images/jetpack6/IMG_4999.PNG)

You'll be prompted with the instructions to prepare for the SDK component
install. Make sure you completed the System Configuration over on the
target Jetson and the OS login screen is displayed:

![SDK component install preparation](https://github.com/boxcutter/kvm/blob/aed72289dda5435ff693119ea74afb4ea311fbf0/docs/images/jetpack6/IMG_5041.PNG)

Enter in the username/password for the user you configured in Ubuntu over
on the target Jetson device, so SDK Manager can login remotely. Then click
on the "Install" button:

![SDK component install](https://github.com/boxcutter/kvm/blob/aed72289dda5435ff693119ea74afb4ea311fbf0/docs/images/jetpack6/IMG_5042.PNG)

SDK Manager will verify target system readiness:

![Verifying readiness](https://github.com/boxcutter/kvm/blob/aed72289dda5435ff693119ea74afb4ea311fbf0/docs/images/jetpack6/IMG_5043.PNG)

And then the SDK install will start:

![SDK Install](https://github.com/boxcutter/kvm/blob/aed72289dda5435ff693119ea74afb4ea311fbf0/docs/images/jetpack6/IMG_5044.PNG)

Click on the "Finish" button once the install is complete.

![SDK Install Complete](https://github.com/boxcutter/kvm/blob/a02cb5f3866f48bf3e0334f5919117c1b81762fb/docs/images/jetpack6/IMG_5046.PNG)

## Verify and complete setup

Once the SDK Manager install is complete, you can disconnect the USB-C
provisioning cable from the target and host PCs.

### Disable screen blanking

```bash
# Prevent the screen from blanking
gsettings set org.gnome.desktop.session idle-delay 0
# Prevent the screen from locking
gsettings set org.gnome.desktop.screensaver lock-enabled false
```

### Configure passwordless sudo and authorized keys

```bash
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/dont-prompt-$USER-for-sudo-password"

sudo apt-get update
sudo apt-get install openssh-server

touch ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
tee -a ~/.ssh/authorized_keys<<EOF
<keys>
EOF
```

### Set the timezone to UTC

http://yellerapp.com/posts/2015-01-12-the-worst-server-setup-you-can-make.html
```bash
sudo timedatectl set-timezone UTC
```

### Install Nomachine

Install Nomachine for ARM https://downloads.nomachine.com/linux/?id=30&distro=Arm

SSH keys
```bash
mkdir -p $HOME/.nx/config
touch $HOME/.nx/config/authorized.crt
chmod 0600 $HOME/.nx/config/authorized.crt
tee -a $HOME/.nx/config/authorized.crt<<EOF
<keys>
EOF
```

### Verify that that the desired version of JetPack is present

Check `/etc/os-release` for the Ubuntu version:

```bash
$ cat /etc/os-release
PRETTY_NAME="Ubuntu 22.04.5 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.5 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy
```

Check `/etc/nv_tegra_release` for the JetPack version:

```bash
$ cat /etc/nv_tegra_release
# R36 (release), REVISION: 4.3, GCID: 38968081, BOARD: generic, EABI: aarch64, DATE: Wed Jan  8 01:49:37 UTC 2025
# KERNEL_VARIANT: oot
TARGET_USERSPACE_LIB_DIR=nvidia
TARGET_USERSPACE_LIB_DIR_PATH=usr/lib/aarch64-linux-gnu/nvidia

$ sudo apt-cache show nvidia-jetpack
Package: nvidia-jetpack
Source: nvidia-jetpack (6.2)
Version: 6.2+b77
Architecture: arm64
Maintainer: NVIDIA Corporation
Installed-Size: 194
Depends: nvidia-jetpack-runtime (= 6.2+b77), nvidia-jetpack-dev (= 6.2+b77)
Homepage: http://developer.nvidia.com/jetson
Priority: standard
Section: metapackages
Filename: pool/main/n/nvidia-jetpack/nvidia-jetpack_6.2+b77_arm64.deb
Size: 29298
SHA256: 70553d4b5a802057f9436677ef8ce255db386fd3b5d24ff2c0a8ec0e485c59cd
SHA1: 9deab64d12eef0e788471e05856c84bf2a0cf6e6
MD5sum: 4db65dc36434fe1f84176843384aee23
Description: NVIDIA Jetpack Meta Package
Description-md5: ad1462289bdbc54909ae109d1d32c0a8

Package: nvidia-jetpack
Source: nvidia-jetpack (6.1)
Version: 6.1+b123
Architecture: arm64
Maintainer: NVIDIA Corporation
Installed-Size: 194
Depends: nvidia-jetpack-runtime (= 6.1+b123), nvidia-jetpack-dev (= 6.1+b123)
Homepage: http://developer.nvidia.com/jetson
Priority: standard
Section: metapackages
Filename: pool/main/n/nvidia-jetpack/nvidia-jetpack_6.1+b123_arm64.deb
Size: 29312
SHA256: b6475a6108aeabc5b16af7c102162b7c46c36361239fef6293535d05ee2c2929
SHA1: f0984a6272c8f3a70ae14cb2ca6716b8c1a09543
MD5sum: a167745e1d88a8d7597454c8003fa9a4
Description: NVIDIA Jetpack Meta Package
Description-md5: ad1462289bdbc54909ae109d1d32c0a8
```

### Verify that the boot drive is the NVMe device

```bash
$ sudo apt-get update
$ sudo apt-get install efibootmgr
# NVMe should be first in the boot order
$ efibootmgr
BootCurrent: 0001
Timeout: 5 seconds
BootOrder: 0001,0000,0002,0003,0004,0005,0006,0007,0008
Boot0000* Enter Setup
Boot0001* UEFI Samsung SSD 990 PRO 4TB S7KGNJ0WC15702M 1
Boot0002* UEFI eMMC Device
Boot0003* UEFI PXEv4 (MAC:48B02DDCCCA5)
Boot0004* UEFI PXEv6 (MAC:48B02DDCCCA5)
Boot0005* UEFI HTTPv4 (MAC:48B02DDCCCA5)
Boot0006* UEFI HTTPv6 (MAC:48B02DDCCCA5)
Boot0007* BootManagerMenuApp
Boot0008* UEFI Shell
```

### Set the power mode to MAX

```bash
# Should be power mode 0
$ sudo nvpmodel -q
NV Power Mode: MODE_30W
2

# If not, set it to 0 - will require reboot
$ sudo nvpmodel -m 0
NVPM WARN: Golden image context is already created
NVPM WARN: Reboot required for changing to this power mode: 0
NVPM WARN: DO YOU WANT TO REBOOT NOW? enter YES/yes to confirm:
yes
NVPM WARN: rebooting
```

### Configure CAN Bus

The built-in can controllers should be automatically created by the `mttcan` driver:

```
$ lsmod | grep mttcan

$ ip -details link show can0
2: can0: <NOARP,ECHO> mtu 16 qdisc noop state DOWN mode DEFAULT group default qlen 10
    link/can  promiscuity 0 minmtu 0 maxmtu 0
    can state STOPPED (berr-counter tx 0 rx 0) restart-ms 0
	  mttcan: tseg1 2..255 tseg2 0..127 sjw 1..127 brp 1..511 brp-inc 1
	  mttcan: dtseg1 1..31 dtseg2 0..15 dsjw 1..15 dbrp 1..15 dbrp-inc 1
	  clock 50000000 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 parentbus platform parentdev c310000.mttcan

$ ip -details link show can0
2: can0: <NOARP,ECHO> mtu 16 qdisc noop state DOWN mode DEFAULT group default qlen 10
    link/can  promiscuity 0 minmtu 0 maxmtu 0
    can state STOPPED (berr-counter tx 0 rx 0) restart-ms 0
	  mttcan: tseg1 2..255 tseg2 0..127 sjw 1..127 brp 1..511 brp-inc 1
	  mttcan: dtseg1 1..31 dtseg2 0..15 dsjw 1..15 dbrp 1..15 dbrp-inc 1
	  clock 50000000 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 parentbus platform parentdev c310000.mttcan
```

Configuring the vcan0 interface on boot

Because Linux for Tegra uses network manager by default instead of systemd-networkd, it
is recommended to use a systemd service to bring up `vcan0` on boot. This makes
the configuration of the vcan0 interface independent of the network service configuration.
This ensures no conflicts happen when both systems are enabled at the same time. Otherwise
you'll need to have `systemd-networkd` enabled to create `vcan0` via netdev or use udev
rules, which will be less reliable than the service configuration.

```
# Create a new service file
sudo tee /etc/systemd/system/vcan.service > /dev/null <<EOF
[Unit]
Description=Virtual CAN interface
Wants=network.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ip link add dev vcan0 type vcan
ExecStart=/sbin/ip link set up vcan0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enabled and start the service
sudo systemctl daemon-reload
sudo systemctl enable vcan.service
sudo systemctl start vcan.service

# Verify that vcan0 is up
$ ip link show vcan0
13: vcan0: <NOARP,UP,LOWER_UP> mtu 72 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/can
```

Testing can configurations:
```
# Install can-utils
sudo apt-get update
sudo apt-get install can-utils

# Start listening for CAN messages
candump vcan0 &

# Send a test CAN message
cansend can0 123#DEADBEEF
```

For more information on configurating the CAN bus refer to the Jetson Linux developer guide:
https://docs.nvidia.com/jetson/archives/r36.4.3/DeveloperGuide/HR/ControllerAreaNetworkCan.html

### Configure KVM/Libvirtd

```
sudo apt-get update
sudo apt-get install libvirt-daemon-system qemu-kvm
sudo adduser $(id -un) libvirt
sudo adduser $(id -un) kvm

# Reboot to restart the QEMU/KVM daemon
sudo reboot
```

Configure wifi as backup connection if configuring over ssh
```
sudo nmcli radio wifi on
# List available wi-fi networks
nmcli dev wifi list
# Connect to a wi-fi- network
sudo nmcli dev wifi connect "network-ssid" password "network-password"
# Optional - prompt for password
# # sudo nmcli --ask dev wifi connect "network-ssid"
# ssh in through wifi
# When done, disable wi-fi
# # sudo nmcli radio wifi off
```

Configure bridged networking

```
# Add the bridge interface
sudo nmcli connection add type bridge ifname br0 con-name br0
# Disable STP for faster port activation
sudo nmcli connection modify br0 bridge.stp no
# Assign an IP to br0
sudo nmcli connection modify br0 ipv4.method auto
# Optional static IP
# nmcli connection modify br0 ipv4.addresses "192.168.1.100/24"
# nmcli connection modify br0 ipv4.gateway "192.168.1.1"
# nmcli connection modify br0 ipv4.dns "8.8.8.8"
# nmcli connection modify br0 ipv4.method manual

# Attach eno1 to the bridge
sudo nmcli connection add type bridge-slave ifname eno1 master br0 con-name bridge-port-eno1
# Apply and activate everything - this will drop your ssh connection so be careful
sudo nmcli connection delete "Wired connection 1"
sudo nmcli connection up br0
sudo nmcli connection up bridge-port-eno1
```

Removing bridge networking
```
# Recreate the standalone connection for eno1
sudo nmcli connection delete "Wired connection 1"
sudo nmcli connection add type ethernet ifname eno1 con-name "Wired connection 1"
sudo nmcli connection modify "Wired connection 1" ipv4.method auto
# This will drop the ssh connection
sudo nmcli connection delete br0

# Delete the old bridge port configuration
sudo nmcli connection delete bridge-port-eno1
```
