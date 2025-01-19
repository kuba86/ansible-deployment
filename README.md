# ansible-deployment
Collection of playbooks for my private home lab

# Setup container
```shell
podman run \
    -it \
    --name ansible \
    --userns=keep-id \
    -v ansible-deployment:/home/core/ansible:z \
    -v .ssh:/home/core/.ssh:z \
    fedora-dev
```

# First run inside container
```shell
sudo dnf -y update; \
pip list --format=json --outdated | jq '.[].name' | xargs pip install --upgrade --no-warn-script-location; \
pip install --no-warn-script-location ansible ansible-dev-tools; \
python3 -m pip install ansible-navigator --user; \
printf "fish_add_path ~/.local/bin" > .config/fish/conf.d/ansible.fish
```

# ssh-add
```shell
eval (ssh-agent -c); \
ssh-add $HOME/.ssh/2024-12-26-ansible; \
cd $HOME/ansible
```

# run ansible-navigator
`ansible-navigator --ee false`
