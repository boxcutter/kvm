# Nvidia Jetson Embedded Computing Board Manual Setup

Nvidia Jetson embedded computer boards are used on robots and drones to
behave as smart cameras.

Helpful video from JetsonHacks YouTube channel on unboxing and setup

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

![SDKManager](https://github.com/boxcutter/kvm/blob/fbafdfaad9aa7cf641cc7cc2c288e3f8c717cb5a/docs/images/jetson/Jan2021-developer-sdkm-landing-page-web-diagram.jpg)

Go to the Nvidia SDK Manager web site:
https://developer.nvidia.com/sdk-manager

Choose to download the NVIDIA SDK Manager:
![Download SDKManager](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/2024-02-03_08-58-50.png)

You’ll need to create an NVDIA account to download:
![Sign up for an NVIDIA account](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2008.59.51.png)

Install the SDK Manager:

`sudo apt-get install ./sdkmanager_[version]-[build#]_amd64.deb`

Then start the SDK Manager with:

`/opt/nvidia/sdkmanager/sdkmanager`

Login with your NVIDIA Developer login again to access the OS boot files:

![NVIDIA Developer Login](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/2024-02-03_09-18-37.png)

It will pop up a separate web browser for you to login with your account

![NVIDIA login](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/2024-02-03_09-19-51.png)

Once you are authenticated it will tell you that you can close the window and use SDK Manager

![Thank You For Using NVDIA SDK Manager](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/2024-02-03_09-21-53.png)

Over in the SDK Manager app it should display a privacy notice, get past this screen:

![Privacy Notice](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/2024-02-03_09-22-20.png)

You’ll need to run a USB-C cable from the Ubuntu 20.04 intel host machine to the Nvidia Jetson. Connect the USB-C cable for the intel host machine to the USB-C port on the side with the 40-pin connector (as it supports both upstream and downstream data):

https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/developer_kit_layout.html

![Flahing port](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/2024-02-03_08-55-58.png)

Connect to the target hardware from your host to the flashing port with a USB-C cable.

When you run SDK Manager with `/opt/nvidia/sdkmanager/sdkmanager` it may detect the target hardware automatically:

![SDK Manager detected device](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.09.58.png)

In Step one - System Configuration, verify that the Host Machine is Ubuntu 20.04 - x86_64 - if not, make sure you’re running on a machine with this configuration! And then make sure the correct target hardware is configured:

![Step Two](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.11.35.png)

In Step one - SDK version, choose JetPack 5.1.3 (we’re not currently using JetPack 6.0 because it is in “developer preview” DP mode, a.k.a. beta):

![SDK Version](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.12.33.png)

JetPack 5.x won’t be an option unless you are running it on Ubuntu 20.04:

![JetPack 5.1.2](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.13.23.png)

JetPack 5.x won’t be an option unless you are running SDK Manager on Ubuntu 20.04:

![Support Host Operating System](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.24.32.png)

Choose the appropriate SDK components in Step Two. You can also choose to download now and install later and store the install files on a shared drive if you want to configure multiple Jetsons:

![Host Components](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.15.37.png)

It may prompt you to create the download folder

![The specified folders don't exist](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.15.57.png)

And it may prompt you to enter in an administrative password

![Enter your password to perform administrative tasks](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.16.48.png)

It will then proceed to download the files for the JetPack version you created - will take 15-20 minutes or more depending on the speed of your internet connection:

![Setup Process](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.17.34.png)

Once the download is complete you’ll need to put the Jetson target hardware into recovery mode to proceed:

![SDK Manager is about to flash your Jetson AGX Orin module](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.28.30.png)

Follow the instructions displayed in the dialog accordingly.

I usually prefer to use manual mode (but automatic mode is fine as well) - if you’re in automatic mode, then you’ll need to hook up a monitor to the Jetson to get its IP address (and it has to have an OS already installed)

Power off the target device. And then on the target device, hit the “Force recovery” button on the front (the middle button) then hold the force recovery button down and hit the “Power button”:

![Force Recovery](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/2024-02-03_10-30-23.png)

![Power](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/2024-02-03_10-35-19.png)

Once the device is in recovery mode (either through manual or automatic methods), once you refresh it should allow you to choose “Pre-config” or “Runtime” configuration. Choose Runtime configuration:
https://docs.nvidia.com/sdk-manager/install-with-sdkm-jetson/index.html

![OEM Configuration](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.49.05.png)

Then choose the NVMe drive as the storage device to configure:

![Storage Device](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.49.49.png)

Once “Runtime” and “NVMe” are selected, then click on the “Flash” button

![Flash](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.50.31.png)

SDK Manager will then continue to flash the device and install the Ubuntu 20.04 OS on the NVMe drive:

![Installing](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2010.51.36.png)

After the flashing step finishes and the device reboots, it will again prompt for the device type. Choose accordingly and click on OK.

![Device Type Again](https://github.com/boxcutter/kvm/blob/c3936088301e5608263873b137a54350b7c4130c/docs/images/jetson/Screenshot%202024-02-03%20at%2011.02.41.png)

Now you’ll need to set up a monitor and configure the username/password. Make sure you use our automation provisioning user: