#!/bin/bash

# https://bugs.launchpad.net/cloud-init/+bug/1890528
# cloud-init can return an exit status on wait other than 0
# so eat the exit status for now so it doesn't error packer
cloud_init_status=0
cloud-init status --wait || cloud_init_status=$?

if [ "$cloud_init_status" = "0" ]; then
  echo "cloud-init succeeded"
else
  echo "cloud-init exit=${cloud_init_status}"
fi
