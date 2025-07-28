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

# First run inside a container
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

## Examples
`:run playbooks/all.yaml -i inventories/prod/hosts.yaml`
`:run playbooks/ntfy-server-boot.yaml -i inventories/prod/hosts.yaml`
### specify user and ad-hoc host
`:run playbooks/ntfy-server-boot.yaml --user=user -i "fedora-kde-xps.tailnet-ba52.ts.net,"`

# Copy fish functions
`cp ../fish-functions/functions/*.fish files/functions/`

# encrypt Caddyfile 
```
ansible-vault encrypt \
files/hosts/wyse01.tailnet-ba52.ts.net/caddy/etc-config/Caddyfile \
--output files/hosts/wyse01.tailnet-ba52.ts.net/caddy/etc-config/Caddyfile.encrypted
```
