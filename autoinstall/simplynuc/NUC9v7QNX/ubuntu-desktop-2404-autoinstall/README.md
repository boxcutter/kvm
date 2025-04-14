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
curl -LO https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso
% shasum -a 256 ubuntu-24.04.2-live-server-amd64.iso
d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d  ubuntu-24.04.2-live-server-amd64.iso

docker pull docker.io/boxcutter/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/polymathrobotics/ubuntu-autoinstall \
    -a autoinstall.yaml \
    -g grub.cfg \
    -i \
    -s ubuntu-24.04.2-live-server-amd64.iso \
    -d ubuntu-autoinstall-NUC9v7QNX.iso
