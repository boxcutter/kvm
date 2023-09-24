#!/bin/sh -eux
export DEBIAN_FRONTEND=noninteractive

echo "==> Install qemu guest agent"
apt-get install -y qemu-guest-agent
apt-get -y autoremove
