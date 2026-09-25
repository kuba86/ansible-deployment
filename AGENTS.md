# AI Agent Guidelines for Ansible Deployment

Read [HOMELAB_CONTEXT.md](HOMELAB_CONTEXT.md) before making changes to understand the infrastructure and project goals.

## Core Architecture
- **Targets**: Fedora CoreOS (wyse01-03), AlmaLinux, Fedora.
- **Workloads**: Podman Quadlets (`.container`, `.pod`) managed via systemd.
- **Dual-Mode Execution**:
  - **Root (LXC containers)**: Config `/etc/containers/systemd`, Unit `/etc/systemd/system`, owner `root:root`, scope `system`.
  - **Rootless (standard hosts)**: Config `~/.config/containers/systemd`, Unit `~/.config/systemd/user`, owner `main_user:main_user`, scope `user`.
  - Auto-detected via facts in `playbooks/common-variables.yaml`, imported by service playbooks.

## Key Rules & Conventions

### 1. Service Playbooks
- **Template First**: ALWAYS copy `playbooks/001-setup.yaml` when adding a service. Replace `AAAAA` placeholders.
- **Naming**: `playbooks/[service].yaml` (NO `setup-` or `install-` prefixes!). Tasks: `[Service] | [Action]`.
- **Variables**: Import `common-variables.yaml` as the first task using `ansible.builtin.import_tasks`; use its calculated variables (`quadlet_dir`, `service_dir`, `file_owner`, `file_group`, `calculated_become`, `systemd_scope`). Never hardcode paths or ownership.
- **Permissions**: Always specify explicit octal `mode` (e.g. `"0640"`, `"0750"`).
- **Handlers**: Trigger service restarts via `notify: Restart service`. Never restart inline.
- **Python / Tooling**: Run Ansible tools with `uv run --locked --group ansible` so versions come from `pyproject.toml` and `uv.lock`. Do not use `uvx` for project Ansible commands or install packages with `pip`.

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

Use the project-pinned Ansible tools via `uv run --locked --group ansible`. Keep `uv.lock` committed and run `uv lock` when dependency declarations change.
Prefer the `ansible` package over installing `ansible-core` directly.

```bash
# Syntax check
uv run --locked --group ansible ansible-playbook --syntax-check playbooks/[service].yaml

# Dry run (check mode)
uv run --locked --group ansible ansible-navigator --ee false run playbooks/[service].yaml -i inventories/prod/hosts.yaml --check

# Deployment (single service / full orchestration / limited host)
uv run --locked --group ansible ansible-navigator --ee false run playbooks/[service].yaml -i inventories/prod/hosts.yaml
uv run --locked --group ansible ansible-navigator --ee false run playbooks/all.yaml -i inventories/prod/hosts.yaml
uv run --locked --group ansible ansible-navigator --ee false run playbooks/[service].yaml -i inventories/prod/hosts.yaml --limit wyse01.tailnet-ba52.ts.net
```

## Ponytail skill

ACTIVATE ON EVERY RESPONSE.
Read and follow `.agents/skills/ponytail/SKILL.md` in full
