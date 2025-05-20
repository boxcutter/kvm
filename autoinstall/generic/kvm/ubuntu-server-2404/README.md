
```
curl -LO https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso

docker pull docker.io/polymathrobotics/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/polymathrobotics/ubuntu-autoinstall \
    -a autoinstall.yaml \
    -g grub.cfg \
    -i \
    -s ubuntu-24.04.2-live-server-amd64.iso \
    -d ubuntu-autoinstall.iso
```
