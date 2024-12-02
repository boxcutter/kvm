```
curl -LO https://releases.ubuntu.com/22.04.5/ubuntu-22.04.5-live-server-amd64.iso

docker pull docker.io/polymathrobotics/ubuntu-autoinstall
docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/polymathrobotics/ubuntu-autoinstall \
    -a autoinstall.yaml \
    -g grub.cfg \
    -i \
    -s ubuntu-22.04.5-live-server-amd64.iso \
    -d ubuntu-autoinstall.iso
```
