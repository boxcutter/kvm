```bash
curl -LO https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso
shasum -a 256 ubuntu-24.04.3-live-server-amd64.iso
c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b  ubuntu-24.04.3-live-server-amd64.iso

docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
  --source ubuntu-24.04.3-live-server-amd64.iso \
  --autoinstall autoinstall.yaml \
  --destination ubuntu-24.04.3-live-server-amd64-autoinstall.iso \
  --grub grub.cfg \
  --loopback loopback.cfg \
  --config-root
```
