#!/usr/bin/env bash

podman run --rm -it --name kanidm-tools \
  --network=host \
  --workdir /root \
  --volume=./files/kanidm/kanidm.config:/data/config:z \
  --volume=./files/kanidm/kanidm.config:/root/.config/kanidm:z \
  --volume=./files/kanidm/kuba86.com.crt:/data/kuba86.com.crt:z \
  --volume=./files/kanidm/.bash_history:/root/.bash_history:z \
  --volume=./files/kanidm/.bashrc:/root/.bashrc:z \
  --volume=./files/kanidm/provision_kanidm_oauth2.sh:/root/provision_kanidm_oauth2.sh:z \
  --volume=./files/kanidm:/root/kanidm-data:z \
  docker.io/kanidm/tools:latest bash
