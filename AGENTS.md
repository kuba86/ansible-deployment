# AI Agent Guidelines for Ansible Deployment

## Core Architecture
- **Targets**: Fedora CoreOS (wyse01-03), AlmaLinux, Fedora.
- **Workloads**: Podman Quadlets (`.container`, `.pod`) managed via systemd.
- **Dual-Mode Execution**:
  - **Root (LXC containers)**: Config `/etc/containers/systemd`, Unit `/etc/systemd/system`, owner `root:root`, scope `system`.
  - **Rootless (standard hosts)**: Config `~/.config/containers/systemd`, Unit `~/.config/systemd/user`, owner `main_user:main_user`, scope `user`.
  - Auto-detected via facts in `playbooks/001-setup.yaml`.

## Key Rules & Conventions

### 1. Service Playbooks
- **Template First**: ALWAYS copy `playbooks/001-setup.yaml` when adding a service. Replace `AAAAA` placeholders.
- **Naming**: `playbooks/[service].yaml` (NO `setup-` or `install-` prefixes!). Tasks: `[Service] | [Action]`.
- **Variables**: Use calculated variables from template (`quadlet_dir`, `service_dir`, `file_owner`, `file_group`, `calculated_become`, `systemd_scope`). Never hardcode paths or ownership.
- **Permissions**: Always specify explicit octal `mode` (e.g. `"0640"`, `"0750"`).
- **Handlers**: Trigger service restarts via `notify: Restart service`. Never restart inline.
- **Python / Tooling**: Run all Python/Ansible tools via `uv` or `uvx` (no local `pip` installs).
  - `uvx` (`uv tool run`): For standalone CLI executables (`uvx ansible-navigator`, `uvx --with ansible-core ansible-playbook`).
  - `uv run`: For executing local Python scripts or commands in a managed environment (`uv run script.py`).

### 2. File Organization
```
ansible-deployment/
├── playbooks/          # [service].yaml, 001-setup.yaml (template), all.yaml
├── files/[service]/    # Quadlets (.container/.pod), configs, scripts
├── inventories/prod/
│   ├── hosts.yaml
│   └── secret_vars/    # {{ inventory_hostname }}/[service].yaml
└── templates/          # Dynamic Jinja2 templates
```

## Validation & Execution Commands

```bash
# Syntax check
uvx --with ansible-core ansible-playbook --syntax-check playbooks/[service].yaml

# Dry run (check mode)
uvx ansible-navigator --ee false run playbooks/[service].yaml -i inventories/prod/hosts.yaml --check

# Deployment (single service / full orchestration / limited host)
uvx ansible-navigator --ee false run playbooks/[service].yaml -i inventories/prod/hosts.yaml
uvx ansible-navigator --ee false run playbooks/all.yaml -i inventories/prod/hosts.yaml
uvx ansible-navigator --ee false run playbooks/[service].yaml -i inventories/prod/hosts.yaml --limit wyse01.tailnet-ba52.ts.net
```
