ip=$(virsh domifaddr ubuntu-desktop-2404 --source agent \
  | awk '$1!="lo" && /ipv4/ {print $4; exit}' \
  | cut -d'/' -f1 
)

docker container run -t --rm \
  --mount type=bind,source="$(pwd)/test",target=/share \
  --env ip \
  docker.io/boxcutter/cinc-auditor exec .  \
    --no-distinct-exit \
    --no-create-lockfile \
    --password superseekret \
    --target "ssh://autobot@${ip}"
