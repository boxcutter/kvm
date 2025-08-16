
```
$ curl -LO https://releases.ubuntu.com/noble/ubuntu-24.04.3-desktop-amd64.iso
$ shasum -a 256 ubuntu-24.04.3-desktop-amd64.iso
faabcf33ae53976d2b8207a001ff32f4e5daae013505ac7188c9ea63988f8328  ubuntu-24.04.3-desktop-amd64.iso

$ docker pull docker.io/boxcutter/ubuntu-autoinstall
$ docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
    -a autoinstall.yaml \
    -g grub.cfg \
    -i \
    -s ubuntu-24.04.3-desktop-amd64.iso \
    -d ubuntu-24.04.3-desktop-autoinstall.iso
```
