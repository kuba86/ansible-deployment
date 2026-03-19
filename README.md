# Ansible Deployment Project

A comprehensive Ansible automation framework for managing home lab infrastructure, designed specifically for containerized environments using Fedora CoreOS, AlmaLinux, and Fedora systems.

## Overview

This project automates the deployment and management of a home lab infrastructure using Ansible. It's optimized for immutable operating systems like Fedora CoreOS and supports containerized workloads with Podman, Incus/LXC, and systemd services.

## Features

- **Immutable OS Support**: Optimized for Fedora CoreOS with rpm-ostree package management
- **Container-First Architecture**: Podman systemd services for application deployment
- **Zero-Trust Networking**: Tailscale VPN integration with exit node capabilities
- **Modern Development Tools**: Scala CLI, Fish shell
- **Infrastructure Services**: Incus clustering, Caddy reverse proxy, Garage HQ object storage
- **Security Hardening**: LUKS encryption, proper privilege escalation
- **Monitoring & Notifications**: ntfy integration for system alerts
- **Modular Design**: Granular playbooks for specific functionality

## Prerequisites

- **Control Node**: Fedora/RHEL/CentOS with Ansible 2.9+
- **Target Hosts**: Fedora CoreOS, AlmaLinux 9, or Fedora 42+
- **Network**: Tailscale account for mesh networking
- **Authentication**: SSH key-based authentication

## Quick Start

### Configure Inventory

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


### Run Playbooks

```shell script
# Full deployment
ansible-navigator --ee false run playbooks/all.yaml -i inventories/prod/hosts.yaml

# Specific service
ansible-navigator --ee false run playbooks/setup-tailscale.yaml -i inventories/prod/hosts.yaml
```


## Supported Systems

| OS            | Package Manager | Status      | Notes                          |
|---------------|-----------------|-------------|--------------------------------|
| Fedora CoreOS | rpm-ostree      | ✅ Primary   | Immutable, container-optimized |
| AlmaLinux 9   | dnf             | ✅ Supported | Enterprise Linux               |
| Fedora 42+    | dnf             | ✅ Supported | Latest features                |

## Security

- **SSH Keys**: Key-based authentication only
- **Privilege Escalation**: Minimal sudo usage with specific tasks
- **Network Security**: Tailscale mesh networking
- **Container Security**: Rootless Podman with systemd integration

## Development

### Adding New Playbooks

1. Create playbook in `playbooks/`
2. Add proper error handling and idempotency

### Testing

```shell script
# Syntax check
ansible-playbook --syntax-check playbooks/test.yaml

# Dry run
ansible-playbook --check playbooks/test.yaml -i inventories/test/hosts.yaml
```

### Other

#### Copy fish functions
`cp ../fish-functions/functions/*.fish files/functions/`

## License

This project is licensed under the terms of the [AGPL-3.0 license](./LICENSE).
