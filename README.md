# Ansible Deployment Project

A comprehensive Ansible automation framework for managing home lab infrastructure, designed specifically for containerized environments using Fedora CoreOS, AlmaLinux, and Fedora systems.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [License](#license)

## Overview

This project automates the deployment and management of a home lab infrastructure using Ansible. It's optimized for immutable operating systems like Fedora CoreOS and supports containerized workloads with Podman, Incus/LXC, and systemd services.

## Features

- **Immutable OS Support**: Optimized for Fedora CoreOS with rpm-ostree package management
- **Container-First Architecture**: Podman systemd services for application deployment
- **Zero-Trust Networking**: Tailscale VPN integration with exit node capabilities
- **Modern Development Tools**: Scala CLI, Fish shell
- **Infrastructure Services**: Incus clustering, Caddy reverse proxy, MinIO object storage
- **Security Hardening**: LUKS encryption, proper privilege escalation, Vault secret management
- **Monitoring & Notifications**: ntfy integration for system alerts
- **Modular Design**: Granular playbooks for specific functionality

## Project Structure
```

ansible-deployment/
├── inventories/          # Host inventories and variables
│   ├── prod/             # Production environment
│   │   ├── hosts.yaml    # Host definitions
│   │   ├── host_vars/    # Per-host variables
│   │   ├── group_vars/   # Group variables
│   │   └── secret_vars/  # Encrypted secrets (Ansible Vault)
│   └── test/             # Test environment
├── playbooks/            # Ansible playbooks
├── files/                # Static files and configurations
│   ├── bin/              # Utility scripts
│   ├── functions/        # Fish shell functions
│   ├── hosts/            # Host-specific configurations
│   └── [services]/       # Service-specific files
├── templates/            # Jinja2 templates
├── ansible.cfg           # Ansible configuration
└── .vault_pass           # Vault password file (gitignored)
```

## Prerequisites

- **Control Node**: Fedora/RHEL/CentOS with Ansible 2.9+
- **Target Hosts**: Fedora CoreOS, AlmaLinux 9, or Fedora 42+
- **Network**: Tailscale account for mesh networking
- **Authentication**: SSH key-based authentication
- **Secrets**: Ansible Vault for sensitive data

## Quick Start

### 1. Container Setup (Recommended)

```bash
# Create and run Ansible container
podman run \
    -it \
    --name ansible \
    --userns=keep-id \
    -v ansible-deployment:/home/core/ansible:z \
    -v .ssh:/home/core/.ssh:z \
    fedora-dev

# Inside container, if not installed - install dependencies
sudo dnf -y update;
pip list --format=json --outdated | jq '.[].name' | xargs pip install --upgrade --no-warn-script-location;
pip install --no-warn-script-location ansible ansible-dev-tools;
python3 -m pip install ansible-navigator --user;
printf "fish_add_path ~/.local/bin" > .config/fish/conf.d/ansible.fish
```

### 2. SSH Agent Setup

```shell script
eval $(ssh-agent -c)
ssh-add $HOME/.ssh/2024-12-26-ansible
cd $HOME/ansible
```


### 3. Configure Inventory

Update `inventories/prod/hosts.yaml` with your infrastructure:

```yaml
all:
  children:
    coreos:
      hosts:
        server01.tailnet-xxx.ts.net:
        server02.tailnet-xxx.ts.net:
    dnf:
      children:
        el9:
          hosts:
            rocky01.tailnet-xxx.ts.net:
```


### 4. Run Playbooks

```shell script
# Full deployment
ansible-navigator --ee false run playbooks/all.yaml -i inventories/prod/hosts.yaml

# Specific service
ansible-navigator --ee false run playbooks/tailscale.yaml -i inventories/prod/hosts.yaml
```


## Supported Systems

| OS            | Package Manager | Status      | Notes                          |
|---------------|-----------------|-------------|--------------------------------|
| Fedora CoreOS | rpm-ostree      | ✅ Primary   | Immutable, container-optimized |
| AlmaLinux 9   | dnf             | ✅ Supported | Enterprise Linux               |
| Fedora 42+    | dnf             | ✅ Supported | Latest features                |

## Playbooks

### Core Infrastructure
- `all.yaml` and `all-coreos.yaml` - Complete infrastructure deployment
- `tailscale.yaml` - Mesh VPN setup with exit nodes
- `setup-users.yaml` - Base user configuration
- `sysctl.yaml` - Kernel parameter tuning
- `setup-dns.yaml` - DNS configuration

### Container Services
- `setup-podman.yaml` - Podman configuration
- `podman-systemd.yaml` - Systemd service creation
- `incus.yaml` - Container orchestration
- `setup-caddy.yaml` - Reverse proxy setup

### Development Tools
- `install-scala-cli.yaml` - Scala CLI installation
- `install-fish.yaml` - Fish shell setup
- `install-fnm.yaml` - Node.js version manager

### Maintenance
- `update-via-dnf.yaml` - System updates
- `luks-regen.yaml` - LUKS key regeneration (TODO)
- `update-ssh-authorized-keys.yaml` - SSH key management

## Inventory Management

The project uses a hierarchical inventory structure:

```
inventories/prod/
├── hosts.yaml           # Host definitions and groups
├── group_vars/         # Variables applied to groups
├── host_vars/          # Host-specific variables
└── secret_vars/        # Ansible Vault encrypted secrets
```

## Security

- **Ansible Vault**: All secrets are encrypted using Vault
- **SSH Keys**: Key-based authentication only
- **Privilege Escalation**: Minimal sudo usage with specific tasks
- **Network Security**: Tailscale mesh networking
- **Container Security**: Rootless Podman with systemd integration

### Vault Usage

```shell script
# Encrypt new files
ansible-vault encrypt secret_vars/host.yaml

# Edit encrypted files
ansible-vault edit secret_vars/host.yaml

# View encrypted files
ansible-vault view secret_vars/host.yaml
```


## Development

### Adding New Playbooks

1. Create playbook in `playbooks/`
2. Follow naming convention: `action-target.yaml`
3. Add proper error handling and idempotency

### Testing

```shell script
# Syntax check
ansible-playbook --syntax-check playbooks/test.yaml

# Dry run
ansible-playbook --check playbooks/test.yaml -i inventories/test/hosts.yaml

# Local testing
ansible-playbook playbooks/test-local.yaml -i "localhost," --connection=local
```

### Other

#### Copy fish functions
`cp ../fish-functions/functions/*.fish files/functions/`

#### encrypt Caddyfile
```
ansible-vault encrypt \
files/hosts/wyse01.tailnet-ba52.ts.net/caddy/etc-config/Caddyfile \
--output files/hosts/wyse01.tailnet-ba52.ts.net/caddy/etc-config/Caddyfile.encrypted
```

## License

This project is licensed under the terms of the [AGPL-3.0 license](./LICENSE).
