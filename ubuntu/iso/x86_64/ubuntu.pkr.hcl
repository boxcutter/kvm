variable "ssh_username" {
  description = "The username to connect to SSH with."
  type        = string
  default     = "packer"
}

variable "ssh_password" {
  description = "A plaintext password to use to authenticate with SSH."
  type        = string
  default     = "packer"
}

# openssl passwd -6 <password>
variable "ssh_crypted_password" {
  type    = string
  default = "$6$T2/U.GUdeHTEXzE1$dE31iksnl.JuMIhZEHxIZPiHngerJS.NuDw4UQ4v7Ih7SEvtSavmg4efqCxRxoM0hc0SQesLdQMYpK95eMwu4."
}

variable "http_directory" {
  description = "Path to a directory to serve using an HTTP server."
  type        = string
  default     = "http"
}

# https://ubuntu.com/server/docs/install/autoinstall
source "file" "user_data" {
  content = <<EOF
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: packer
    username: ${var.ssh_username}
    password: ${var.ssh_crypted_password}
  early-commands:
    # otherwise packer tries to connect and exceeds max attempts
    - systemctl stop ssh.service
    - systemctl stop ssh.socket
  ssh:
    install-server: yes
    allow-pw: yes
  late-commands:
    - echo '${var.ssh_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${var.ssh_username}
    - |
      if [ -d /sys/firmware/efi ]; then
        apt-get install -y efibootmgr
        efibootmgr -o $(efibootmgr | sed -n 's/Boot\(.*\)\* ubuntu/\1/p')
      fi
EOF
  target  = "${var.http_directory}/user-data"
}

source "file" "meta_data" {
  content = <<EOF
EOF
  target  = "${var.http_directory}/meta-data"
}

build {
  sources = ["sources.file.user_data", "sources.file.meta_data"]
}

variable "boot_command" {
  type = list(string)
  default = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall 'ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ---",
    "<enter>",
    "initrd /casper/initrd",
    "<enter>",
    "boot<enter><wait>",
  ]
}

variable "efi_boot" {
  description = "Boot in EFI mode instead of BIOS."
  type        = bool
  default     = false
}

variable "efi_firmware_code" {
  description = "Path to the CODE part of the firmware."
  type        = string
  default     = null
}

variable "efi_firmware_vars" {
  description = "Path to the VARS corresponding to the code file."
  type        = string
  default     = null
}

variable "iso_checksum" {
  description = "The checksum for the ISO file or virtual hard drive."
  type        = string
  default     = "file:https://releases.ubuntu.com/22.04.3/SHA256SUMS"
}

variable "iso_url" {
  description = "A URL to the ISO containing the installation image or virtual hard drive file to clone."
  type        = string
  default     = "https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso"
}

variable "vm_name" {
  description = "The name of the image file for the new virtual machine."
  type        = string
  default     = "ubuntu-22.04-bios-x86_64.qcow2"
}

source "qemu" "ubuntu" {
  # Ubuntu 20.04 image default timeout is 5s, so we need to be fast
  boot_wait = "5s"
  boot_command = var.boot_command
  accelerator       = "kvm"
  cpus              = 2
  disk_interface    = "virtio-scsi"
  disk_size         = "16G"
  disk_compression  = true
  format            = "qcow2"
  headless          = false
  http_directory    = var.http_directory
  iso_checksum      = var.iso_checksum
  iso_url           = var.iso_url
  machine_type      = "q35"
  memory            = 4096
  net_device        = "virtio-net"
  output_directory  = "output-${trimsuffix(var.vm_name, ".qcow2")}"
  shutdown_command  = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password      = var.ssh_password
  ssh_timeout       = "30m"
  ssh_username      = var.ssh_username
  vm_name           = var.vm_name
  efi_boot          = var.efi_boot
  efi_firmware_code = var.efi_firmware_code
  efi_firmware_vars = var.efi_firmware_vars
  qemuargs = [
    ["-cpu", "host"]
  ]
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
