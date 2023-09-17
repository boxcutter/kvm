source "file" "user_data" {
  content = <<EOF
#cloud-config

password: ubuntu
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

source "qemu" "ubuntu" {
  disk_compression = true
  disk_image = true
  disk_size = "30G"
  iso_checksum = var.iso_checksum
  iso_url = var.iso_url
  qemuargs = [
    ["-cdrom", "cidata.iso"]
  ]
  shutdown_command = "sudo shutdown -P now"
  ssh_password = "ubuntu"
  ssh_timeout = "120s"
  ssh_username = "ubuntu"
}

build {
  sources = ["source.qemu.ubuntu"]
}
