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

## First steps - verify the Jetson is booting off NVMe and has at least 2TB of storage

### Verify that JetPack 5.1.x is present
If you think your Jetson Developer Kit has already been configured, double
check to make sure the system has the desired JetPack version and there is
adequate storage.

Make sure that you installed the right version of the OS - because JetPack 6.x is
still in beta, we currently prefer Ubuntu 20.04 with JetPack 5.1.x.

```bash
automat@agx01:~/Downloads$ cat /etc/os-release 
NAME="Ubuntu"
VERSION="20.04.6 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.6 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal

automat@agx01:~/Downloads$ cat /etc/nv_tegra_release 
# R35 (release), REVISION: 4.1, GCID: 33958178, BOARD: t186ref, EABI: aarch64, DATE: Tue Aug  1 19:57:35 UTC 2023

automat@agx01:~/Downloads$ sudo apt-cache show nvidia-jetpack
Package: nvidia-jetpack
Version: 5.1.2-b104
Architecture: arm64
Maintainer: NVIDIA Corporation
Installed-Size: 194
Depends: nvidia-jetpack-runtime (= 5.1.2-b104), nvidia-jetpack-dev (= 5.1.2-b104)
Homepage: http://developer.nvidia.com/jetson
Priority: standard
Section: metapackages
Filename: pool/main/n/nvidia-jetpack/nvidia-jetpack_5.1.2-b104_arm64.deb
Size: 29304
SHA256: fda2eed24747319ccd9fee9a8548c0e5dd52812363877ebe90e223b5a6e7e827
SHA1: 78c7d9e02490f96f8fbd5a091c8bef280b03ae84
MD5sum: 6be522b5542ab2af5dcf62837b34a5f0
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
JetPack 5.x. We work with both versions of JetPack:

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
   pressing the (1) "Power button" (the left button). Then release both buttons.

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
