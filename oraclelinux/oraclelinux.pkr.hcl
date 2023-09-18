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
instance-id: oraclelinux-cloud
local-hostname: oraclelinux-cloud
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
  default = "sha256:67b644451efe5c9c472820922085cb5112e305fedfb5edb1ab7020b518ba8c3b"
}

variable "iso_url" {
  type    = string
  default = "https://yum.oracle.com/templates/OracleLinux/OL8/u8/x86_64/OL8U8_x86_64-kvm-b198.qcow"
}

variable "vm_name" {
  type = string
  default = "oraclelinux-8-x86_64"
}

source "qemu" "oraclelinux" {
  disk_compression = true
  disk_image = true
  disk_size = "48G"
  iso_checksum = var.iso_checksum
  iso_url = var.iso_url
  qemuargs = [
    ["-cdrom", "cidata.iso"]
  ]
  output_directory = "output-${var.vm_name}"
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  ssh_password = var.ssh_password
  ssh_timeout = "120s"
  ssh_username = var.ssh_username
  vm_name = var.vm_name
}

build {
  sources = ["source.qemu.oraclelinux"]
}
