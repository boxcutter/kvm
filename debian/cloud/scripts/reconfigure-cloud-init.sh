#!/bin/sh -eux
export DEBIAN_FRONTEND=noninteractive

echo "==> Reconfiguring cloud-init sources"
cat <<EOF >/etc/cloud/cloud.cfg.d/90_dpkg.cfg;
# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ NoCloud, None ]
EOF
