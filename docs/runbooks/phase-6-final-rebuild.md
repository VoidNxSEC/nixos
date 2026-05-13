# Runbook: Phase 6 — Final System Rebuild

**Goal**: Confirm all changes work end-to-end with an actual `nixos-rebuild switch`.

**Pre-condition**: Phases 3–5 complete, `nix flake check` passes clean.

---

## 1. Pre-rebuild checklist

```bash
# 1. Flake is valid
nix flake check

# 2. No stale references to removed modules
grep -r "machine-learning\|modules/soc\b\|modules/ai\b\|modules/debug\b" \
  /etc/nixos/flake.nix /etc/nixos/hosts --include="*.nix"
# Expected: no output

# 3. No hardcoded paths remaining in modules
grep -r "/home/kernelcore" /etc/nixos/modules --include="*.nix"
# Expected: no output

# 4. All 3 hosts visible
nix flake show 2>&1 | grep nixosConfigurations
```

---

## 2. Dry-run build (no system switch)

```bash
# Build the derivation without activating
nix build /etc/nixos#nixosConfigurations.kernelcore.config.system.build.toplevel \
  --no-link --print-build-logs 2>&1 | tail -30
```

If this fails: read the Nix error, fix the offending module, re-check, repeat.

---

## 3. Switch

```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore 2>&1 | tee /tmp/rebuild-$(date +%Y%m%d).log
```

---

## 4. Post-rebuild validation

```bash
# Check for activation errors
journalctl -b -p err --since "5 minutes ago"

# Verify key services
systemctl status --no-pager | grep failed

# Spot-check enabled modules
systemctl status pipewire      # audio
systemctl status tailscaled    # network
systemctl status docker        # containers
```

---

## 5. If rebuild fails

```bash
# System rollback (boot into previous generation)
sudo nixos-rebuild switch --rollback

# Or from boot menu: select previous NixOS generation
```

Git state is unaffected — roll back git separately if needed:
```bash
git reset --hard snapshot/2026-05-02-pre-consolidation
```

---

## 6. Tag and push

```bash
git tag -a v2.0.0-community -m "Community-ready: parameterized, consolidated, documented"
git push origin main
git push origin v2.0.0-community
```

---

## Done criteria

- [ ] `nixos-rebuild switch` completes without errors
- [ ] `journalctl -b -p err` shows no new failures
- [ ] All daily-use services running
- [ ] Git tag pushed
- [ ] `snapshot/2026-05-02-pre-consolidation` branch retained for reference
