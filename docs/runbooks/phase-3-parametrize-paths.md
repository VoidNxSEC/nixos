# Runbook: Phase 3 — Parametrize Hardcoded Paths

**Goal**: Replace every hardcoded `/home/kernelcore` and literal `"kernelcore"` username
in `modules/` and `hosts/` with the `system.user.*` options defined in
`modules/system/user-config.nix`.

**Pre-condition**: `nix flake check` passes before starting.

**Rollback**: `git reset --hard HEAD` at any point.

---

## 1. Discover all occurrences

```bash
# Hardcoded home paths in modules
grep -rn "/home/kernelcore" /etc/nixos/modules --include="*.nix" | tee /tmp/phase3-paths.txt

# Hardcoded username literals (not option names)
grep -rn '"kernelcore"' /etc/nixos/modules --include="*.nix" \
  | grep -v 'config\.kernelcore\|options\.kernelcore' \
  | tee /tmp/phase3-usernames.txt

# Hardcoded paths in hosts
grep -rn "/home/kernelcore" /etc/nixos/hosts --include="*.nix" | tee -a /tmp/phase3-paths.txt

# Summary
echo "Path occurrences:    $(wc -l < /tmp/phase3-paths.txt)"
echo "Username occurrences: $(wc -l < /tmp/phase3-usernames.txt)"
```

---

## 2. Replacement patterns

### 2a. Home directory paths

| Before | After |
|--------|-------|
| `"/home/kernelcore"` | `config.system.user.homeDir` |
| `"/home/kernelcore/projects"` | `config.system.user.projectsDir` |
| `"/home/kernelcore/.config"` | `config.system.user.configDir` |
| `home = "/home/kernelcore/..."` | `home = "${config.system.user.homeDir}/..."` |

### 2b. Username literals in user/group contexts

| Before | After |
|--------|-------|
| `users.users.kernelcore` | `users.users."${config.system.user.username}"` |
| `users.groups.kernelcore` | `users.groups."${config.system.user.username}"` |
| `home-manager.users.kernelcore` | `home-manager.users."${config.system.user.username}"` |
| `owner = "kernelcore"` | `owner = config.system.user.username` |

---

## 3. Execution strategy

Process modules **one category at a time** to keep diffs reviewable:

```bash
# For each category:
# 1. Edit files manually (or use sed carefully)
# 2. Validate Nix syntax
# 3. Run nix flake check
# 4. Commit

CATEGORIES=(system hardware audio security network services development ml containers virtualization desktop applications programs tools shell secrets blockchain)

for cat in "${CATEGORIES[@]}"; do
  echo "=== Processing modules/$cat ==="
  grep -rln "/home/kernelcore" /etc/nixos/modules/$cat --include="*.nix" 2>/dev/null
  grep -rln '"kernelcore"' /etc/nixos/modules/$cat --include="*.nix" 2>/dev/null
done
```

### Validate each file after editing:
```bash
nix-instantiate --parse /etc/nixos/modules/CATEGORY/file.nix
```

### Checkpoint after each category:
```bash
nix flake check
git add -p && git commit -m "refactor(system): parametrize paths in modules/CATEGORY"
```

---

## 4. Host files

After modules are clean, do hosts:

```bash
grep -rn "/home/kernelcore\|\"kernelcore\"" /etc/nixos/hosts --include="*.nix"
```

In `hosts/kernelcore/configuration.nix`, the username is deliberately set:
```nix
system.user.username = "kernelcore";  # intentional — this is the actual machine
```
That's fine — it's an explicit override, not a hardcode.

---

## 5. Final check

```bash
# No more hardcoded paths (outside of intentional host overrides)
grep -r "/home/kernelcore" /etc/nixos/modules --include="*.nix"
# Expected: no output

nix flake check
# Expected: passes
```

---

## Done criteria

- [ ] `grep -r "/home/kernelcore" modules/` returns nothing
- [ ] `grep -r '"kernelcore"' modules/` returns only `config.system.user.*` patterns
- [ ] `nix flake check` passes
- [ ] Git committed per category
