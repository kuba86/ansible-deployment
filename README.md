# Ansible Deployment Project

A comprehensive Ansible automation framework for managing home lab infrastructure, designed specifically for containerized environments using Fedora CoreOS, AlmaLinux, and Fedora systems.

## Overview

This project automates the deployment and management of a home lab infrastructure using Ansible. It's optimized for immutable operating systems like Fedora CoreOS and supports containerized workloads with Podman (Quadlets) and systemd services.

## Quick Start

### Configure Inventory

Update `inventories/prod/hosts.yaml` with your infrastructure.

### Run Playbooks

```shell script
# Full deployment
ansible-navigator --ee false run playbooks/all.yaml -i inventories/prod/hosts.yaml

# Specific service
ansible-navigator --ee false run playbooks/tailscale.yaml -i inventories/prod/hosts.yaml
```

## Supported Systems

- **Fedora CoreOS** (Primary)
- **AlmaLinux 9**
- **Fedora 42+**

## Development

- Follow the template in `playbooks/001-setup.yaml` for new services.
- Keep playbooks idempotent and use handlers for service restarts.
- Refer to `.junie/guidelines.md` for detailed project overview and best practices.

## License

This project is licensed under the terms of the [AGPL-3.0 license](./LICENSE).
