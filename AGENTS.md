# AI Agent Guidelines for Ansible Deployment Project

## Project Overview

This repository manages a home lab infrastructure using Ansible automation. It deploys and configures **46+ services** across multiple hosts running Fedora CoreOS, AlmaLinux, and Fedora. The infrastructure is built on:
- **Podman Quadlets** for containerized workloads
- **systemd** for service management
- **Tailscale** for secure networking
- Support for both root and rootless container deployments

## Critical Context

### Infrastructure Design
- **Immutable OS Focus**: Primary targets are Fedora CoreOS hosts (wyse01-03)
- **Container-First**: Services run as Podman containers via systemd Quadlets
- **Dual-Mode Execution**: Playbooks auto-detect and handle both:
  - Root execution (in LXC containers)
  - Rootless execution (standard hosts with `main_user`)

### Repository Structure
```
ansible-deployment/
├── playbooks/          # 46 service playbooks + orchestration
│   ├── 001-setup.yaml  # TEMPLATE for new services
│   ├── all.yaml        # Main orchestration playbook
│   ├── all-coreos.yaml # CoreOS-specific tasks
│   └── [service].yaml  # Individual service playbooks
├── files/              # Service configs, Quadlet files, scripts
│   └── [service]/      # Organized by service name
├── inventories/prod/
│   ├── hosts.yaml      # Infrastructure inventory
│   └── secret_vars/    # Encrypted host/service variables
└── templates/          # Jinja2 templates for dynamic configs
```

## Ansible Best Practices

### 1. Playbook Creation & Naming
- **NO "setup-" or "install-" prefixes** in filenames or task names
- Name playbooks after the service: `caddy.yaml`, `ntfy.yaml`, `kanidm.yaml`
- Task names format: `[Service] | [Action]` (e.g., `Caddy | Deploy Quadlet file`)
- **ALWAYS use `playbooks/001-setup.yaml` as the template** for new services

### 2. The Template Pattern (`001-setup.yaml`)
When creating new service playbooks, the template provides:

**Essential Variable Detection:**
```yaml
- name: [Service] | variables (detect container)
  ansible.builtin.set_fact:
    run_as_root: "{{ ansible_facts['virtualization_tech_guest'] | default([]) | intersect(['lxc', 'container']) | length > 0 }}"

- name: [Service] | variables (compute once, reuse everywhere)
  ansible.builtin.set_fact:
    service_dir: "{{ '/etc/systemd/system' if run_as_root else '/home/' ~ main_user ~ '/.config/systemd/user' }}"
    quadlet_dir: "{{ '/etc/containers/systemd' if run_as_root else '/home/' ~ main_user ~ '/.config/containers/systemd' }}"
    file_owner: "{{ 'root' if run_as_root else main_user }}"
    file_group: "{{ 'root' if run_as_root else main_user }}"
    calculated_become: "{{ run_as_root }}"
    systemd_scope: "{{ 'system' if run_as_root else 'user' }}"
```

**Key Template Features:**
- Auto-detects LXC/container environments
- Calculates correct paths for systemd/Quadlet directories
- Sets proper ownership/permissions based on context
- Handles `become` elevation automatically
- Includes handler pattern for service restarts

### 3. Variable Management
```yaml
vars_files:
  - "../inventories/prod/secret_vars/all.yaml"  # Global secrets

pre_tasks:
  - name: Gather per-host secret files
    ansible.builtin.include_vars:
      file: "{{ item }}"
    loop:
      - "../inventories/prod/secret_vars/{{ inventory_hostname }}/base.yaml"
      - "../inventories/prod/secret_vars/{{ inventory_hostname }}/[service].yaml"
    when: lookup('ansible.builtin.fileglob', item) | length > 0
```

### 4. File & Directory Operations
**Always specify ownership and permissions:**
```yaml
- name: [Service] | Deploy Quadlet file
  ansible.builtin.template:
    src: "../files/[service]/[service].container"
    dest: "{{ quadlet_dir }}/[service].container"
    owner: "{{ file_owner }}"
    group: "{{ file_group }}"
    mode: "0640"
  become: "{{ calculated_become }}"
  notify: Restart service

- name: [Service] | Create data directory
  ansible.builtin.file:
    path: "/var/mnt/data/[service]"
    state: directory
    owner: "{{ file_owner }}"
    group: "{{ file_group }}"
    mode: "0750"
  become: "{{ calculated_become }}"
```

### 5. Handler Pattern for Service Restarts
**Define handler once, reuse via `notify`:**
```yaml
tasks:
  - name: [Service] | Deploy config
    ansible.builtin.template:
      # ...
    notify: Restart service

handlers:
  - name: Restart service
    ansible.builtin.systemd:
      daemon_reload: true
      name: [service].service
      state: restarted
      enabled: true
      scope: "{{ systemd_scope }}"
    become: "{{ calculated_become }}"
```

### 6. Idempotency Requirements
- All tasks must be idempotent (safe to run multiple times)
- Use `changed_when` to control change reporting
- Avoid tasks that always report "changed" unnecessarily
- Test with `--check` mode when possible

### 7. Host Targeting
Common host groups in `inventories/prod/hosts.yaml`:
- `coreos`: Fedora CoreOS hosts (wyse01-03)
- `dnf`: DNF-based systems (AlmaLinux, Fedora)
- `desktop`: Workstation machines
- `all`: All managed hosts

Target appropriately in playbook headers:
```yaml
- name: [Service Name]
  hosts: coreos:dnf  # Multiple groups with colon
  gather_facts: true
```

## Working with This Repository

### Adding a New Service
1. **Copy the template:** `cp playbooks/001-setup.yaml playbooks/[service].yaml`
2. **Replace all "AAAAA" placeholders** with the actual service name
3. **Create service directory:** `mkdir files/[service]`
4. **Add Quadlet/config files** to `files/[service]/`
5. **Create host-specific secrets** in `inventories/prod/secret_vars/[host]/[service].yaml`
6. **Verify syntax:** `ansible-playbook --syntax-check playbooks/[service].yaml`
7. **Add to orchestration:** Include in `playbooks/all.yaml` if needed

### Modifying Existing Services
1. **Locate playbook:** `playbooks/[service].yaml`
2. **Check for dependencies:** Review imports in `all.yaml` and related playbooks
3. **Update configs:** Modify files in `files/[service]/`
4. **Test changes:** Run with `--check` flag first
5. **Verify:** Check syntax and run targeted playbook

### Understanding Service Execution
Services can run in two modes:
- **Root mode** (detected in LXC containers):
  - Files: `/etc/systemd/system/`, `/etc/containers/systemd/`
  - Ownership: `root:root`
  - Scope: `system`
- **Rootless mode** (standard hosts):
  - Files: `~/.config/systemd/user/`, `~/.config/containers/systemd/`
  - Ownership: `main_user:main_user`
  - Scope: `user`

The template handles this automatically via `run_as_root` detection.

## Verification & Testing

### Syntax Validation
```bash
ansible-playbook --syntax-check playbooks/[service].yaml
```

### Dry Run (Check Mode)
```bash
ansible-navigator --ee false run playbooks/[service].yaml \
  -i inventories/prod/hosts.yaml --check
```

### Actual Deployment
```bash
# Single service
ansible-navigator --ee false run playbooks/[service].yaml \
  -i inventories/prod/hosts.yaml

# All services
ansible-navigator --ee false run playbooks/all.yaml \
  -i inventories/prod/hosts.yaml
```

### Host-Specific Execution
```bash
ansible-navigator --ee false run playbooks/[service].yaml \
  -i inventories/prod/hosts.yaml --limit wyse01.tailnet-ba52.ts.net
```

## Common Patterns & Anti-Patterns

### ✅ DO
- Use the `001-setup.yaml` template for consistency
- Leverage `calculated_become`, `file_owner`, `file_group` variables
- Use handlers for service restarts
- Store service configs in `files/[service]/`
- Keep playbooks focused on single services
- Specify file modes in octal format: `"0640"`, `"0750"`

### ❌ DON'T
- Use "setup-" or "install-" prefixes
- Hardcode paths to `/etc/systemd/system/` or user directories
- Hardcode `root` ownership or `become: true`
- Restart services inline (use handlers instead)
- Skip ownership/permission specifications
- Create playbooks without testing `--syntax-check`

## Key Services in This Repository

The infrastructure includes 46+ services including:
- **Networking:** Tailscale, Cloudflared, Caddy (reverse proxy)
- **Storage:** Garage (S3), Syncthing, SFTPGo, Rclone
- **Containers:** Incus (LXC management), K3s (Kubernetes)
- **Identity:** Kanidm (IdP)
- **Monitoring:** Home Assistant, ntfy (notifications)
- **Productivity:** CryptPad, Stirling-PDF
- **Development:** Node.js (fnm), Fish shell
- **Automation:** Restic backups, Let's Encrypt SSL

Each service has its own playbook in `playbooks/` and config files in `files/`.

## AI Agent Success Tips

1. **Always start with the template** when creating new services
2. **Never hardcode paths or permissions** - use the template variables
3. **Check existing playbooks** for similar services before creating new patterns
4. **Validate syntax** before claiming completion
5. **Understand the dual-mode execution** model (root vs. rootless)
6. **Follow the naming conventions** strictly - no "setup-" prefixes
7. **Use handlers** for service management
8. **Test changes** with `--check` when possible
9. **Keep configs organized** in service-specific directories under `files/`
10. **Document host-specific variables** in the appropriate secret_vars location
