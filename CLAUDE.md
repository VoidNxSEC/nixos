# NixOS Configuration — Project Guide

> Flake-based NixOS configuration for the VoidNxSEC hosts.
> Architecture source of truth: [docs/architecture/TOPOLOGY.md](docs/architecture/TOPOLOGY.md)
> (target topology) and [docs/architecture/INVENTORY.md](docs/architecture/INVENTORY.md)
> (regenerable inventory). The 7-phase restructuring described in TOPOLOGY.md
> was completed in 2026-07; this file describes the resulting layout.

## Layout

```
flake.nix                  # Entry point: 3 nixosConfigurations, checks, templates
hosts/
├── kernelcore/            # Main workstation — one .nix per area (desktop.nix,
│   │                      #   ml.nix, security.nix, ...), thin over modules/
│   ├── specialisations/   # Boot-selectable environments (k8s-prod, emergency, ...)
│   ├── home/              # Home Manager (glassmorphism theme, waybar, ...)
│   └── users/
├── k8s-node/              # Kubernetes node config
└── workstation/           # Secondary host
modules/                   # ~20 categories; ALL options live under kernelcore.*
├── security/              # Hardening (imported last — highest priority)
├── ml/  network/  services/  shell/  desktop/  virtualization/  ...
lib/                       # Packages, dev shells, helpers
overlays/
secrets/                   # SOPS-encrypted only — never plaintext secrets
scripts/                   # Categorized (secrets/ diagnostics/ nix/ git/ ...);
                           #   files at the root are PINNED by runtime paths in .nix
docs/                      # Categorized (guides/ mcp/ runbooks/ architecture/ ...);
                           #   3 root .md files are pinned by shell aliases
tests/                     # NixOS VM tests, exposed as flake checks (test-*)
```

## Conventions

- **Namespace**: every option declared in this repo lives under `kernelcore.*`
  (e.g. `kernelcore.ml.llamacpp.enable`). No new options under `services.*`,
  `programs.*`, etc. Gate: the grep in TOPOLOGY.md §8 (Fase 1) must stay empty.
- **Enable flags**: modules use `mkEnableOption ... // { default = true; }`
  when they gate previously-unconditional config — hosts and specialisations
  can turn them off without changing behavior for existing systems.
- **Aggregators**: each `modules/<category>/default.nix` imports its
  submodules; `flake.nix` imports categories, not individual files.
- **Security order**: `modules/security/` (includes `hardening.nix`, the
  former `sec/hardening.nix`) is imported last; use `mkForce` only there.
- **Pinned files**: before moving anything under `scripts/` or `docs/`, grep
  for runtime references (`/etc/nixos/...` paths, shell aliases) — pinned
  files stay in place, or every reference moves with them.
- Comments in **new files are written in English**; the `typos` CI job is the
  radar for remaining Portuguese content (informational, `continue-on-error`).

## Build & Validation

```bash
# Canonical validation (used by CI; pure eval, no build):
nix eval --raw .#nixosConfigurations.kernelcore.config.system.build.toplevel.drvPath

# Equivalent form:
nix build --dry-run .#nixosConfigurations.kernelcore.config.system.build.toplevel

nix flake check --no-build   # fmt + package checks + test instantiation
nix fmt .                    # nixfmt-tree
nix build .#checks.x86_64-linux.test-security   # run a VM test (heavy)
```

- Refactors should be provable: compare the toplevel `drvPath` before/after —
  an identical hash means an identical system.
- **The switch is manual and belongs to the user.** Never run
  `nixos-rebuild switch`; validate and hand over.
- Run toolchain commands (`python3`, `cargo`, `npm`, ...) inside
  `nix develop --command <cmd>`, never directly on the host.

## Hard Rules (safety)

- **Never** set `networking.nftables.enable = true` — it breaks Docker.
- In nftables rules use `iifname` (not `iif`) for dynamic interfaces
  (VM TAPs / veths) that may not exist at ruleset load time.
- Never run commands that could drop the active connection
  (WiFi/SSH/Tailscale) without an explicit warning and user confirmation.
- Secrets only via sops-nix; `users.mutableUsers = false`.

## CI (GitHub Actions)

| Workflow | Purpose |
|---|---|
| `ci.yml` | fmt check + eval of the 3 nixosConfigurations + flake checks |
| `quality.yml` | statix / deadnix / typos (informational, `continue-on-error` until debt is zero) |
| `security.yml` | org reusable security scan + vulnix (non-blocking) |
| `docs.yml` | docs generation |
| `update-flake-lock.yml` | weekly flake.lock update PR |

Deploy/switch is never done by CI.

## Further Instructions

Workflow and diagnosis rules for Claude sessions live in
[.claude/CLAUDE.md](.claude/CLAUDE.md). Emergency procedures:
[docs/NIX-EMERGENCY-PROCEDURES.md](docs/NIX-EMERGENCY-PROCEDURES.md).
MCP server docs: [docs/mcp/](docs/mcp/).
