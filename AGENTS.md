# Repository Guidelines

This repository contains a NixOS flake that defines hosts, modules, dev shells, and build artifacts (ISO/VM image/container). Follow the practices below to contribute safely and predictably.

## GPT Agent Playbook
- **Stay sandbox aware**: Commands default to `bash -lc` with `workdir` set; respect the current sandbox/approval policy before running anything that writes, touches secrets, or needs network.
- **Plan when work is multi-step**: Use the planning tool for anything non-trivial (≥2 steps); never submit a single-step plan and update it as steps finish.
- **Inspect before you edit**: Prefer `rg`/`rg --files` to locate context, and read files with `sed`/`nl` before changing them.
- **Edit carefully**: Use `apply_patch` for hand-written changes; avoid it for generated content or large refactors.
- **Validate what you touch**: Run the smallest relevant check (`nix fmt`, `nix flake check`, targeted scripts) whenever feasible; if you skip validation, call it out.
- **Communicate crisply**: Final replies lead with the change, list affected paths with line refs, and suggest obvious next steps (rebuild, tests, commits) when they exist.
- **Signal completion**: Keep the closing tone friendly and concise; when rebuilds are needed, point to the `rebuild` alias instead of restating full commands.
- **Verify wiring**: After adding helpers or modules, confirm they are referenced by searching the tree (`rg <symbol>`) so we know the code path is live.
- **Ask follow-ups**: When context is missing or risks remain, surface focused follow-up questions before moving ahead so we stay proactive on issues and tasks.

### Permissible Commands
- Read-only inspection: `ls`, `find`, `rg`, `cat`, `sed`, `nl`, `head`, `tail`, `stat` (never modify state).
- Git hygiene: `git status`, `git diff`, `git show`, `git rev-parse` (no commits or resets without direction).
- Nix tooling: `nix fmt`, `nix flake check`, `nix build`, `nix develop` (watch for derivations that download or require root).
- System introspection: `systemctl status <svc>`, `journalctl -u <svc> --no-pager | head`, `nvidia-smi` (status only, no restarts).
- Safe scripting helpers: `/nix/store/*/bin/python -c '...'`, `jq`, `awk` for data inspection; avoid scripts that write outside the workspace.
- When in doubt, assume write/network/privileged operations need approval or an explicit user request before execution.

## Project Structure & Module Organization
- Root: `flake.nix`/`flake.lock` (entrypoint, formatter, checks, packages, devShells)
- Hosts: `hosts/<host>/...` (per‑machine configs; main host: `kernelcore`)
- Modules: `modules/<domain>/<name>.nix` (feature‑scoped; security loaded last)
- Lib/Overlays: `lib/*.nix`, `overlays/` (dev shells, custom packages)
- Secrets: `secrets/*.env.enc` (SOPS‑encrypted); policy in `.sops.yaml`
- Scripts: `scripts/*.sh` (diagnostics/migrations); Docs in `docs/`

## Build, Test, and Development Commands
- Format: `nix fmt` (uses `nixfmt-rfc-style`; CI enforces)
- Checks: `nix flake check` (format check + key builds)
- Build ISO: `nix build .#iso`  | VM image: `nix build .#vm-image`
- Switch host: `sudo nixos-rebuild switch --flake .#kernelcore`
- Dry test host: `sudo nixos-rebuild test --flake .#kernelcore`
- Dev shells: `nix develop .#python | .#node | .#rust | .#infra | .#cuda`
- Secrets edit: `nix develop -c secrets-edit dev` or `./scripts/add-secret.sh`
- After config changes: run `nix flake check` to trigger formatter hooks and basic CI checks before committing.

## Coding Style & Naming Conventions
- Nix style: run `nix fmt` before commit. Prefer 2‑space indent, trailing commas in attrsets.
- Filenames: kebab‑case `*.nix` (e.g., `wifi-optimization.nix`, `gpu-orchestration.nix`).
- Module layout: group by domain (`modules/security/*`, `modules/network/*`); keep small, composable modules.

## Testing Guidelines
- Always run `nix flake check` locally.
- For host changes, run `sudo nixos-rebuild test --flake .#<host>` on the target machine.
- If you touch packages/overlays, build the artifact you changed (e.g., `nix build .#image-app`).

## Commit & Pull Request Guidelines
- Commits: imperative, concise, and scoped. Recommended pattern:
  - `modules/security: harden sshd options`
  - `hosts/kernelcore: enable nordvpn`
- PRs must include: summary, affected paths, rationale, screenshots or logs when relevant, and `nix flake check` output. Link issues when applicable.

## Security & Configuration Tips
- Never commit plaintext secrets. Use SOPS: `secrets/<env>.env.enc` managed via `secrets-edit` (AGE via SSH host key per flake).
- Review security modules loaded last under `modules/security/*` and final overrides in `sec/hardening.nix`.

## Architecture Overview
- Single primary host `nixosConfigurations.kernelcore` composed from layered modules. Overlays and packages live in `overlays/` and `lib/packages.nix`. CI runs formatter and key builds via `checks`.
