packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "cpus" {
  type    = number
  default = 1
  description = "The number of virtual cpus to use when building the VM."
}

variable "memory" {
  type    = number
  default = 2048
  description = "The amount of memory to use when building the VM in megabytes. This defaults to 512 megabytes."
}

variable "efi_boot" {
  type    = bool
  default = false
}

variable "efi_firmware_code" {
  type    = string
  default = "/usr/share/OVMF/OVMF_CODE_4M.fd"
}

variable "efi_firmware_vars" {
  type    = string
  default = "/usr/share/OVMF/OVMF_VARS_4M.fd"
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
  default = "almalinux-9-x86_64"
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
instance-id: almalinux-cloud
local-hostname: almalinux-cloud
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
  default = "file:https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/CHECKSUM"
}

variable "iso_url" {
  type    = string
  default = "https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
}

source "qemu" "almalinux" {
  cpu_model        = "host"
  cpus             = var.cpus
  memory           = var.memory
  disk_compression = true
  disk_image       = true
  disk_size        = "32G"
  headless         = var.headless
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  machine_type     = "q35"
  qemuargs = [
    ["-cdrom", "boot-${var.vm_name}/cidata.iso"]
  ]
  output_directory = "output-${var.vm_name}"
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password     = var.ssh_password
  ssh_timeout      = "120s"
  ssh_username     = var.ssh_username
  vm_name          = "${var.vm_name}.qcow2"
  efi_boot          = true
  efi_firmware_code = var.efi_firmware_code
  efi_firmware_vars = var.efi_firmware_vars
}

build {
  sources = ["source.qemu.almalinux"]

  # cloud-init may still be running when we start executing scripts
  # To avoid race conditions, make sure cloud-init is done first
  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    scripts = [
      "../scripts/cloud-init-wait.sh",
    ]
  }
}
