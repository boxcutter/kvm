# Nvidia Jetson Embedded Computing Board Manual Setup

Helpful video on unboxing and setup

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

## First steps - install an NVMe drive and flash with SDK Manager

The Jetson Developer Kits are configured to boot and run the OS off the
built-in eMMC drive. The eMMC drive is fairly small, and eMMC is slow. So
it is better to just reconfigure the system so it boots off the secondary
NVMe drive exclusively and ignores the eMMC device. (However the eMMC can
be used as a secondary boot partition for disaster recovery).

You’ll need a second x86_64 intel PC running Ubuntu 20.04 to install and
Flash the OS in the NVidia Target device (because we’re still using
JetPack 5.x):

![SDKManager](https://github.com/boxcutter/kvm/raw/docs/images/jetson/Jan2021-developer-sdkm-landing-page-web-diagram.jpg "jetson-images")
