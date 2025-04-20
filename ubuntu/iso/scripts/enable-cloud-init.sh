#!/bin/sh -eux
export DEBIAN_FRONTEND=noninteractive

echo "==> Enabling cloud-init"
cloud-init clean --machine-id
