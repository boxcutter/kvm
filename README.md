# kvm

Packer templates for producing KVM/QEMU images written in HCL.

This repo contains source code that can be used to create a
pipeline that customizes the qcow2 base images from all of the major Linux
distros. You can use these examples to create your own customized
minimalizst Linux images with "Just Enough Operating System" to
bootstrap an appliance with further automation specific to your use case.

Examples are provided that create virtual machines images for both
x86_64 and ARM64 processors with hardware acceleration. For x86_64 processors,
examples are provided images with either the Unified Extensible Firmware
Interface (UEFI) (TianoCore) or Legacy 16-bit X86 BIOS firmware (SeaBIOS).
Since ARM64 processors don't support Legacy BIOS firmware,
only UEFI examples are provided for ARM64.

> NOTE: We don't bother creating vagrant boxes compatible with the
> vagrant-libvirt plugin. There's no ARM64 version of vagrant for Linux.
> The vagrant-libvirt hasn't been updated in almost a year, as of this writing,
> and it's complicated to install and troubleshoot issues.
> It's just easier to avoid using vagrant entirely and use libvirt or qemu
> to work with the qcow2 images directly.

For more information on using libvirt or qemu to work with qcow2
images directly, refer to https://taylorific.github.io/kvm-training

## Building the images

Prequisites:

- Install [Hashicorp Packer](docs/INSTALL_PACKER.md)
- Install [QEMU/KVM](docs/INSTALL_QEMU_KVM.md)

In the root of this repo there are directories with examples for the following
distros:

- [almalinux/cloud](almalinux/cloud)
- [amazonlinux/cloud](amazonlinux/cloud)
- [centos/cloud](centos/cloud)
- [debian/cloud](debian/cloud)
- [oraclelinux/cloud](oraclelinux/cloud)
- [rockylinux/cloud](rockylinux/cloud)
- [ubuntu/cloud](ubuntu/cloud)

Each distro directory has a subdirectory for each processor architecture. You'll
want to make each directory the current directory when run Hashcirop packer
to create images for each processor. There's also a `scripts` directory that
contains shared code referenced by each processor build.

- `aarch64` - ARM64 processor architecture
- `x86_64` - X86_64/AMD64/Intel 64 processor architecture
