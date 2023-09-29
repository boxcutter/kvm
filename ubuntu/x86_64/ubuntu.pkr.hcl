variable "efi_boot" {
  type    = bool
  default = false
}

variable "efi_firmware_code" {
  type    = string
  default = null
}

variable "efi_firmware_vars" {
  type    = string
  default = null
}

variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "ssh_password" {
  type    = string
  default = "packer"
}

source "file" "user_data" {
  content = <<EOF
#cloud-config
user: ${var.ssh_username}
password: ${var.ssh_password}
chpasswd: { expire: False }
ssh_pwauth: True
EOF
  target  = "user-data"
}

source "file" "meta_data" {
  content = <<EOF
instance-id: ubuntu-cloud
local-hostname: ubuntu-cloud
EOF
  target  = "meta-data"
}

build {
  sources = ["sources.file.user_data", "sources.file.meta_data"]

  provisioner "shell-local" {
    inline = ["genisoimage -output cidata.iso -input-charset utf-8 -volid cidata -joliet -r user-data meta-data"]
  }
}

variable "iso_checksum" {
  type    = string
  default = "file:http://cloud-images.ubuntu.com/releases/22.04/release/SHA256SUMS"
}

variable "iso_url" {
  type    = string
  default = "http://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "vm_name" {
  type    = string
  default = "ubuntu-22.04-x86_64"
}

source "qemu" "ubuntu" {
  disk_compression = true
  disk_image       = true
  disk_size        = "16G"
  iso_checksum     = var.iso_checksum
  iso_url          = var.iso_url
  qemuargs = [
    ["-cdrom", "cidata.iso"]
  ]
  output_directory  = "output-${var.vm_name}"
  shutdown_command  = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password      = var.ssh_password
  ssh_timeout       = "120s"
  ssh_username      = var.ssh_username
  vm_name           = var.vm_name
  efi_boot          = var.efi_boot
  efi_firmware_code = var.efi_firmware_code
  efi_firmware_vars = var.efi_firmware_vars
}

build {
  sources = ["source.qemu.ubuntu"]

  # cloud-init may still be running when we start executing scripts
  # To avoid race conditions, make sure cloud-init is done first
  provisioner "shell" {
    inline = [
      "echo '==> Waiting for cloud-init to finish'",
      "/usr/bin/cloud-init status --wait",
      "echo '==> Cloud-init complete'",
    ]
  }

  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts = [
      "../scripts/disable-updates.sh",
      "../scripts/qemu.sh",
    ]
  }
}
