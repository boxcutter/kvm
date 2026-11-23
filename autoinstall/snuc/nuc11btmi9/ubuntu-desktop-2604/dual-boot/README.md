```
$ curl -LO \
    https://releases.ubuntu.com/resolute/ubuntu-26.04.1-desktop-amd64.iso
# shasum -a 256 ubuntu-26.04.1-desktop-amd64.iso
601e30fbf5d97759367c632e2c33630665039b7e2158fd068403da3ccf1bda1f  ubuntu-26.04.1-desktop-amd64.iso

docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
  --source ubuntu-26.04.1-desktop-amd64.iso \
  --autoinstall autoinstall.yaml \
  --destination ubuntu-26.04.1-desktop-amd64-nuc11btmi9-autoinstall.iso \
  --grub grub.cfg \
  --loopback loopback.cfg \
  --config-root
```

```
docker container run --rm --interactive --tty \
  --mount type=bind,source="$(pwd)/test",target=/share \
  docker.io/boxcutter/cinc-auditor exec example \
    --key-files /Users/taylor/.ssh/id_ed25519 \
    --target ssh://autobot@10.63.33.125

docker container run --rm --interactive --tty \
  --mount type=bind,source="$(pwd)",target=/share \
  docker.io/boxcutter/cinc-auditor exec /share/test \
    --no-create-lockfile \
    --no-distinct-exit \
    --password superseekret \
    --target ssh://autobot@10.63.33.171
```
