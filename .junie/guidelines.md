# Project Overview

This repository contains Ansible playbooks and configurations for managing a home lab infrastructure. It is optimized for containerized workloads using Podman (Quadlets) and supports various distributions including Fedora CoreOS, AlmaLinux, and Fedora.

## Project Structure

- `playbooks/`: Contains Ansible playbooks for system setup, application deployment, and maintenance.
- `files/`: Configuration files and templates (e.g., systemd services, Quadlet files) organized by service.
- `inventories/`: Infrastructure definitions and secret variables.
- `templates/`: Ansible Jinja2 templates.

## Ansible Best Practices

To maintain consistency and readability, follow these guidelines for playbooks and tasks:

### Playbooks and Tasks
- **Naming**: Avoid "setup-" or "install-" prefixes in file names and task names. The playbook name should represent the service or function (e.g., `sftpgo.yaml` instead of `setup-sftpgo.yaml`).
- **Templates**: Use the `001-setup.yaml` template for new service playbooks. This template includes logic for:
  - Detecting container environments (`run_as_root`).
  - Calculating systemd and Quadlet directories for both root and rootless (user) services.
  - Setting correct ownership and permissions based on the execution context.
- **Idempotency**: All tasks must be idempotent.
- **Handlers**: Use handlers for service restarts instead of inline tasks when possible.

### File and Directory Management
- Use `ansible.builtin.file` for directory creation.
- Use `ansible.builtin.template` for dynamic configuration files.
- Always specify `owner`, `group`, and `mode` (using octal format, e.g., `"0644"`) for files and directories.

### Variables
- Load global secrets from `../inventories/prod/secret_vars/all.yaml`.
- Load host-specific variables in `pre_tasks` using `ansible.builtin.include_vars`.

## Verifying Changes
- Use `ansible-playbook --syntax-check playbooks/<filename>.yaml` to verify playbook syntax.
- Use `--check` for dry runs when possible.
