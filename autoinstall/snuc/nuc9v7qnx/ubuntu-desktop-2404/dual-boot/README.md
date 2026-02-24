```
$ curl -LO https://releases.ubuntu.com/24.04.3/ubuntu-24.04.4-desktop-amd64.iso
$ shasum -a 256 ubuntu-24.04.4-desktop-amd64.iso
3a4c9877b483ab46d7c3fbe165a0db275e1ae3cfe56a5657e5a47c2f99a99d1e  ubuntu-24.04.4-desktop-amd64.iso

docker run -it --rm \
  --mount type=bind,source="$(pwd)",target=/data \
  docker.io/boxcutter/ubuntu-autoinstall \
  --source ubuntu-24.04.4-desktop-amd64.iso \
  --autoinstall autoinstall.yaml \
  --destination ubuntu-24.04.4-desktop-amd64-autoinstall.iso \
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
