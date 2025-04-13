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
