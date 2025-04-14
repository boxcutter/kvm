```
curl -LO https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-desktop-amd64.iso
% shasum -a 256 ubuntu-24.04.2-desktop-amd64.iso
d7fe3d6a0419667d2f8eff12796996328daa2d4f90cd9f87aa9371b362f987bf  ubuntu-24.04.2-desktop-amd64.iso

docker pull docker.io/boxcutter/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/polymathrobotics/ubuntu-autoinstall \
    -a autoinstall.yaml \
    -g grub.cfg \
    -i \
    -s ubuntu-24.04.2-desktop-amd64.iso \
    -d ubuntu-autoinstall-NUC9v7QNX.iso
```
