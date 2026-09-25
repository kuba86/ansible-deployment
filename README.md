# Ansible Deployment

Ansible automation for a homelab running Podman Quadlet workloads on Fedora CoreOS, AlmaLinux, and Fedora.

## Documentation

- [Agent guidelines](AGENTS.md) — conventions, tooling, and validation commands for all contributors and AI agents.
- [Homelab context](HOMELAB_CONTEXT.md) — infrastructure, services, and project goals.

## Usage

Ansible tools are pinned in `pyproject.toml` and `uv.lock`. Run them with `uv run --locked --group ansible` to use the locked versions:

```bash
uv run --locked --group ansible ansible-navigator --ee false run playbooks/all.yaml -i inventories/prod/hosts.yaml
```

## License

This project is licensed under the terms of the [AGPL-3.0 license](./LICENSE).
