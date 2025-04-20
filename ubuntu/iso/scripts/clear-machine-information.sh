#!/bin/bash

echo "==> Autoremove packages and clear the package cache"
apt-get --assume-yes autoremove
apt-get --assume-yes clean

echo "==> Reset machine ID"
truncate -s 0 /etc/machine-id
[ -f /var/lib/dbus/machine-id ] && truncate -s 0 /var/lib/dbus/machine-id

echo "==> Remove SSH host keys (will be regenerated on first boot)"
rm --force /etc/ssh/ssh_host_*

echo "==> Remove the random seed file (will be regenerated on first boot)"
systemctl --quiet is-active systemd-random-seed.service && systemctl stop systemd-random-seed.service
[ -f /var/lib/systemd/random-seed ] && rm --force /var/lib/systemd/random-seed

echo "==> Clear log files"
find /var/log -type f -delete

echo "==> Clear the bash history"
export HISTSIZE=0
truncate -s 0 ~/.bash_history
unset HISTFILE
