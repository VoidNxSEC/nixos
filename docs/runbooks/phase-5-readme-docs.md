# Runbook: Phase 5 — README & Community Documentation

**Goal**: Create a top-level `README.md` and supporting docs that present
this repo as a community NixOS framework — clear, welcoming, accurate.

**Pre-condition**: Phases 3–4 complete. Repo structure is stable.

---

## 1. Root README.md

Create `/etc/nixos/README.md` with these sections (in order):

1. **Title + one-line description**
   "Comprehensive, modular NixOS configuration framework. Fork and adapt."

2. **What's included** (feature checklist)
   - Desktop (Hyprland/Niri), audio production, dev environments
   - Security hardening (SOC, EDR, IDS/Suricata, SIEM)
   - ML/AI (llama.cpp, vLLM, agent ecosystem)
   - Kubernetes, CI/CD, blockchain tooling
   - Secrets management (sops-nix), Home Manager

3. **Quick start** (3 paths)
   - Use as template: clone, generate hardware-config, override username
   - Cherry-pick modules: import specific modules in your flake
   - Learn: browse `modules/` — each module is self-contained

4. **Repository structure** (visual tree)

5. **Customization** — changing username, adding modules, personal flake inputs

6. **Security notes** — hardening, SOC, secrets pattern

7. **Contributing** — link to CONTRIBUTING.md

8. **License**

---

## 2. CONTRIBUTING.md

Create `/etc/nixos/CONTRIBUTING.md`:

- Fork → branch → change → `nix flake check` → PR
- Module requirements: `mkOption` + description on every option, `mkEnableOption` for toggles
- No hardcoded usernames or paths (use `config.system.user.*`)
- Commit message convention: `feat(module):`, `fix(module):`, `refactor:`

---

## 3. hosts/README.md

Already designed in plan. Create `/etc/nixos/hosts/README.md`:

- Explain `_examples/` as starting points
- Show the 3-step "add my machine" flow
- Document the `system.user.username` override

---

## 4. modules/README.md

Create `/etc/nixos/modules/README.md`:

Table of all module categories with one-line purpose:

| Module | Purpose |
|--------|---------|
| `ml/` | ML/AI: inference, model serving, agent ecosystem |
| `security/` | Hardening + SOC (IDS, EDR, SIEM) |
| `desktop/` | Wayland, Hyprland, Niri |
| ... | ... |

---

## 5. flakes/README.md

Document the personal.nix pattern. Link to `personal.nix.example`.

---

## 6. Archive noisy docs

`docs/` has 80+ files, many personal/ephemeral. Sweep:

```bash
# Move clearly personal/ephemeral docs to docs/archive/
ls docs/*.md | wc -l   # count

# Candidates for archive (personal incident logs, Portuguese-only debug notes):
# docs/EMERGENCIA-LIBERAR-ESPACO.md
# docs/EXECUTAR-AGORA.md
# docs/commits-a2b22cd-af0b0dc.md
# etc.

# Keep: architecture docs, guides/, setup docs with community value
```

---

## Done criteria

- [ ] `README.md` exists at repo root — complete and accurate
- [ ] `CONTRIBUTING.md` exists
- [ ] `hosts/README.md` explains the `_examples/` pattern
- [ ] `modules/README.md` is a useful index
- [ ] `flakes/README.md` documents the personal.nix pattern
- [ ] `docs/` trimmed of clearly personal/ephemeral files
