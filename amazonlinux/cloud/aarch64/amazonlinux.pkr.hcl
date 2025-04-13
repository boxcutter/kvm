packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "headless" {
  type    = bool
  default = true
}

variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "ssh_password" {
  type    = string
  default = "packer"
}

variable "vm_name" {
  type    = string
  default = "amazonlinux-2023-aarch64"
}

source "file" "user_data" {
  content = <<EOF
#cloud-config
user: ${var.ssh_username}
password: ${var.ssh_password}
chpasswd: { expire: False }
ssh_pwauth: True
EOF
  target  = "boot-${var.vm_name}/user-data"
}

source "file" "meta_data" {
  content = <<EOF
instance-id: amazonlinux-2023
local-hostname: amazonlinux-2023
EOF
  target  = "boot-${var.vm_name}/meta-data"
}

build {
  sources = ["sources.file.user_data", "sources.file.meta_data"]

  provisioner "shell-local" {
    inline = ["genisoimage -output boot-${var.vm_name}/cidata.iso -input-charset utf-8 -volid cidata -joliet -r boot-${var.vm_name}/user-data boot-${var.vm_name}/meta-data"]
  }
}

variable "iso_checksum" {
  type    = string
  default = "file:https://cdn.amazonlinux.com/os-images/2.0.20240610.1/kvm/SHA256SUMS"
}

variable "iso_url" {
  type    = string
  default = "https://cdn.amazonlinux.com/os-images/2.0.20240610.1/kvm/amzn2-kvm-2.0.20240610.1-x86_64.xfs.gpt.qcow2"
}

source "qemu" "amazonlinux" {
  disk_compression = true
  disk_image       = true
  disk_size        = "32G"
  format           = "qcow2"
  headless         = var.headless
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  machine_type     = "virt,gic-version=max"
  net_device       = "virtio-net"
  disk_interface   = "virtio"
  qemu_binary      = "qemu-system-aarch64"
  qemuargs = [
    ["-cdrom", "boot-${var.vm_name}/cidata.iso"],
    ["-cpu", "max"],
    ["-boot", "strict=on"],
    ["-monitor", "none"],
    /* ["-device", "virtio-gpu-pci"], */
  ]
  output_directory = "output-${var.vm_name}"
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password     = var.ssh_password
  ssh_timeout      = "120s"
  ssh_username     = var.ssh_username
  vm_name          = "${var.vm_name}.qcow2"
  efi_boot          = true
  efi_firmware_code = "/usr/share/AAVMF/AAVMF_CODE.fd"
  efi_firmware_vars = "/usr/share/AAVMF/AAVMF_VARS.fd"
}

build {
  sources = ["source.qemu.amazonlinux"]

  # cloud-init may still be running when we start executing scripts
  # To avoid race conditions, make sure cloud-init is done first
  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    scripts = [
      "../scripts/cloud-init-wait.sh",
    ]
  }
}
