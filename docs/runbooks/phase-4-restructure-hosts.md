# Runbook: Phase 4 — Restructure Hosts & Clean flake.nix

**Goal**: Update `flake.nix` to remove personal SSH inputs, wire hosts to `_examples/`
templates, and ensure all three hosts (`kernelcore`, `workstation`, `k8s-node`) build cleanly.

**Pre-condition**: Phase 3 complete, `nix flake check` passes.

---

## 1. Clean flake.nix inputs

### 1a. Identify all personal inputs
```bash
grep -n 'url = "git+ssh\|url = "path:/home' /etc/nixos/flake.nix
```

### 1b. Move personal inputs out

For each SSH/path input:
- If the module is NOT currently used by any enabled host → **comment out with note**
- If it IS used → move to `flakes/personal.nix` pattern and document

Pattern for commented inputs:
```nix
# ── PERSONAL: add to flakes/personal.nix ─────────────────
# ml-offload-api.url = "git+ssh://git@github.com/.../ml-offload-api";
```

### 1c. Clean commented-out dead inputs
Remove blocks like:
```nix
#cognitive-vault = { url = ...; };
#vmctl = { url = ...; };
```
These are just clutter. If needed, they're in the `snapshot/2026-05-02-pre-consolidation` branch.

---

## 2. Update flake.nix outputs

Ensure `nixosConfigurations` is clean — no `specialArgs` leaking personal objects:

```nix
nixosConfigurations = {
  kernelcore = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit self; };
    modules = [
      sops-nix.nixosModules.sops
      home-manager.nixosModules.home-manager
      ./hosts/kernelcore/configuration.nix
    ];
  };

  workstation = nixpkgs.lib.nixosSystem { ... };
  k8s-node = nixpkgs.lib.nixosSystem { ... };
};
```

---

## 3. Update host configurations

### kernelcore (actual machine)
`hosts/kernelcore/configuration.nix` should:
- Import `./hardware-configuration.nix` (stays machine-specific)
- Import `../_examples/desktop-workstation.nix`
- Override: `system.user.username = "kernelcore";`
- Override: `networking.hostName = "kernelcore";`
- Add only machine-specific extras (NVIDIA, specific ML configs)

### workstation
Same pattern — import from `_examples/desktop-workstation.nix` or create a new example if it's meaningfully different.

### k8s-node
Import from `_examples/k8s-node.nix` and override hostname.

---

## 4. Clean backup files

```bash
git rm hosts/kernelcore/configuration.nix.backup 2>/dev/null
git rm hosts/kernelcore/configuration.nix.bak 2>/dev/null
git rm hosts/kernelcore/configurations-template.nix 2>/dev/null
```

---

## 5. Validate

```bash
nix flake check
nix flake show  # Should list all 3 hosts cleanly
```

---

## 6. Dry-run build

```bash
nix build .#nixosConfigurations.kernelcore.config.system.build.toplevel \
  --dry-run 2>&1 | tail -20
```

---

## Done criteria

- [ ] `flake.nix` has zero `git+ssh://` or `path:/home/` inputs
- [ ] All three hosts listed in `nix flake show`
- [ ] `nix flake check` passes
- [ ] No `.backup` / `.bak` files in hosts/
- [ ] Dry-run build succeeds
